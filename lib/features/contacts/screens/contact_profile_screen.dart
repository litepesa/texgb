import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/contacts/providers/contacts_provider.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class ContactProfileScreen extends ConsumerStatefulWidget {
  final UserModel contact;

  const ContactProfileScreen({
    Key? key,
    required this.contact,
  }) : super(key: key);

  @override
  ConsumerState<ContactProfileScreen> createState() => _ContactProfileScreenState();
}

class _ContactProfileScreenState extends ConsumerState<ContactProfileScreen> {
  late UserModel _contact;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _contact = widget.contact;
  }

  Future<void> _blockContact() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(contactsNotifierProvider.notifier).blockContact(_contact);
      if (mounted) {
        showSnackBar(context, 'Contact blocked successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to block contact: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeContact() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(contactsNotifierProvider.notifier).removeContact(_contact);
      if (mounted) {
        showSnackBar(context, 'Contact removed successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to remove contact: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modernTheme = context.modernTheme;
    final primaryColor = modernTheme.primaryColor!;
    final textColor = modernTheme.textColor!;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Profile image
                  Hero(
                    tag: 'contact-${_contact.uid}',
                    child: _contact.image.isNotEmpty
                        ? Image.network(
                            _contact.image,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: primaryColor.withOpacity(0.7),
                            child: Center(
                              child: Text(
                                _contact.name.isNotEmpty ? _contact.name[0] : '?',
                                style: const TextStyle(
                                  fontSize: 80,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                  ),
                  // Gradient overlay for better title visibility
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.7, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(_contact.name),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.chat),
                tooltip: 'Message',
                onPressed: () {
                  // Start chat
                  showSnackBar(context, 'Chat feature coming soon');
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'block':
                      _showBlockConfirmationDialog();
                      break;
                    case 'remove':
                      _showRemoveConfirmationDialog();
                      break;
                    case 'share':
                      // Share contact profile
                      showSnackBar(context, 'Share feature coming soon');
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share),
                        SizedBox(width: 10),
                        Text('Share contact'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'block',
                    child: Row(
                      children: [
                        Icon(Icons.block),
                        SizedBox(width: 10),
                        Text('Block contact'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline),
                        SizedBox(width: 10),
                        Text('Remove contact'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              // Contact Info Card
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contact Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      // Phone
                      ListTile(
                        leading: Icon(
                          Icons.phone,
                          color: primaryColor,
                        ),
                        title: const Text('Phone'),
                        subtitle: Text(_contact.phoneNumber),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chat),
                              onPressed: () {
                                // Message
                                showSnackBar(context, 'Chat feature coming soon');
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.call),
                              onPressed: () {
                                // Call
                                showSnackBar(context, 'Call feature coming soon');
                              },
                            ),
                          ],
                        ),
                      ),
                      // Last Seen
                      if (_contact.lastSeen.isNotEmpty)
                        ListTile(
                          leading: Icon(
                            Icons.access_time,
                            color: primaryColor,
                          ),
                          title: const Text('Last Seen'),
                          subtitle: Text(_formatLastSeen(_contact.lastSeen)),
                        ),
                      // About
                      if (_contact.aboutMe.isNotEmpty)
                        ListTile(
                          leading: Icon(
                            Icons.info_outline,
                            color: primaryColor,
                          ),
                          title: const Text('About'),
                          subtitle: Text(_contact.aboutMe),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Status updates (placeholder)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Status Updates',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // View all status updates
                              showSnackBar(context, 'Status updates coming soon');
                            },
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const Divider(),
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No status updates available',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Media, Links, Docs (placeholder)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Shared Media',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // View all media
                              showSnackBar(context, 'Shared media coming soon');
                            },
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const Divider(),
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No shared media available',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Block and Remove buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _showBlockConfirmationDialog,
                        icon: const Icon(Icons.block),
                        label: const Text('Block'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _showRemoveConfirmationDialog,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remove'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
            ]),
          ),
        ],
      ),
    );
  }

  String _formatLastSeen(String lastSeenTimestamp) {
    try {
      final lastSeen = DateTime.fromMicrosecondsSinceEpoch(
          int.parse(lastSeenTimestamp));
      final now = DateTime.now();
      final difference = now.difference(lastSeen);

      if (difference.inSeconds < 60) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
      } else {
        // Format date for older timestamps
        return '${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  void _showBlockConfirmationDialog() {
    showMyAnimatedDialog(
      context: context,
      title: 'Block Contact',
      content: 'Are you sure you want to block ${_contact.name}? They won\'t be able to message or call you.',
      textAction: 'Block',
      onActionTap: (confirmed) {
        if (confirmed) {
          _blockContact();
        }
      },
    );
  }

  void _showRemoveConfirmationDialog() {
    showMyAnimatedDialog(
      context: context,
      title: 'Remove Contact',
      content: 'Are you sure you want to remove ${_contact.name} from your contacts?',
      textAction: 'Remove',
      onActionTap: (confirmed) {
        if (confirmed) {
          _removeContact();
        }
      },
    );
  }
}