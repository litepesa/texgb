// lib/features/groups/screens/group_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/groups/providers/groups_providers.dart';
import 'package:textgb/features/groups/screens/group_members_screen.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class GroupSettingsScreen extends ConsumerWidget {
  final String groupId;

  const GroupSettingsScreen({
    super.key,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modernTheme = context.modernTheme;
    final groupAsync = ref.watch(groupDetailProvider(groupId));
    final membershipAsync = ref.watch(currentUserMembershipProvider(groupId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Settings'),
      ),
      body: groupAsync.when(
        data: (group) => membershipAsync.when(
          data: (membership) {
            final isAdmin = membership?.isAdmin ?? false;
            final isCreator = group.creatorId == currentUser?.uid;

            return ListView(
              children: [
                // Group info header
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: modernTheme.surfaceVariantColor,
                        backgroundImage: group.hasImage
                            ? NetworkImage(group.groupImageUrl!)
                            : null,
                        child: group.hasImage
                            ? null
                            : Icon(
                                Icons.group,
                                size: 50,
                                color: modernTheme.textColor,
                              ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        group.name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: modernTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        group.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: modernTheme.textSecondaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${group.memberCount} ${group.memberCount == 1 ? 'member' : 'members'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: modernTheme.textTertiaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),

                // Members
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Members'),
                  subtitle: Text('${group.memberCount} members'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            GroupMembersScreen(groupId: groupId),
                      ),
                    );
                  },
                ),
                const Divider(),

                // Admin-only settings
                if (isAdmin) ...[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'ADMIN SETTINGS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: modernTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Edit Group Info'),
                    onTap: () {
                      _showEditGroupDialog(context, ref, group);
                    },
                  ),
                  if (isCreator)
                    ListTile(
                      leading: Icon(Icons.delete, color: modernTheme.errorColor),
                      title: Text(
                        'Delete Group',
                        style: TextStyle(color: modernTheme.errorColor),
                      ),
                      onTap: () {
                        _showDeleteGroupDialog(context, ref, groupId);
                      },
                    ),
                  const Divider(),
                ],

                // Leave group
                ListTile(
                  leading: Icon(Icons.exit_to_app, color: modernTheme.warningColor),
                  title: Text(
                    'Leave Group',
                    style: TextStyle(color: modernTheme.warningColor),
                  ),
                  onTap: () {
                    _showLeaveGroupDialog(
                        context, ref, groupId, currentUser?.uid);
                  },
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  void _showEditGroupDialog(BuildContext context, WidgetRef ref, group) {
    final nameController = TextEditingController(text: group.name);
    final descController = TextEditingController(text: group.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Group Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(groupDetailProvider(groupId).notifier).updateGroup(
                      name: nameController.text.trim(),
                      description: descController.text.trim(),
                    );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Group updated')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteGroupDialog(BuildContext context, WidgetRef ref, String groupId) {
    final modernTheme = context.modernTheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text(
          'Are you sure you want to delete this group? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(groupsListProvider.notifier).deleteGroup(groupId);
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close settings
                  Navigator.pop(context); // Close chat
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Group deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: modernTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showLeaveGroupDialog(
      BuildContext context, WidgetRef ref, String groupId, String? userId) {
    if (userId == null) return;
    final modernTheme = context.modernTheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref
                    .read(groupMembersProvider(groupId).notifier)
                    .leaveGroup(userId);
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close settings
                  Navigator.pop(context); // Close chat
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Left group')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: modernTheme.warningColor),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}
