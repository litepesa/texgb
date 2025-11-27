// lib/features/groups/screens/group_members_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/groups/providers/groups_providers.dart';
import 'package:textgb/features/groups/widgets/member_tile.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class GroupMembersScreen extends ConsumerWidget {
  final String groupId;

  const GroupMembersScreen({
    super.key,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modernTheme = context.modernTheme;
    final membersAsync = ref.watch(groupMembersProvider(groupId));
    final membershipAsync = ref.watch(currentUserMembershipProvider(groupId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
        actions: [
          // Add member button (admin only)
          membershipAsync.when(
            data: (membership) {
              if (membership?.isAdmin ?? false) {
                return IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: () => _showAddMembersDialog(context, ref),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: membersAsync.when(
        data: (members) {
          if (members.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: modernTheme.textSecondaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No members',
                    style: TextStyle(
                      fontSize: 18,
                      color: modernTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            );
          }

          final isCurrentUserAdmin =
              membershipAsync.valueOrNull?.isAdmin ?? false;

          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final isSelf = member.userId == currentUser?.uid;

              return MemberTile(
                member: member,
                isSelf: isSelf,
                isCurrentUserAdmin: isCurrentUserAdmin,
                onPromote: () async {
                  try {
                    await ref
                        .read(groupMembersProvider(groupId).notifier)
                        .promoteMember(member.userId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('${member.displayName} promoted to admin')),
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
                onDemote: () async {
                  try {
                    await ref
                        .read(groupMembersProvider(groupId).notifier)
                        .demoteMember(member.userId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('${member.displayName} demoted to member')),
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
                onRemove: () {
                  _showRemoveMemberDialog(context, ref, member);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: modernTheme.errorColor,
              ),
              const SizedBox(height: 16),
              Text('Error: $error'),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(groupMembersProvider(groupId));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddMembersDialog(BuildContext context, WidgetRef ref) {
    final modernTheme = context.modernTheme;
    final TextEditingController searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final allUsers = ref.watch(usersProvider);
          final currentMembers = ref.watch(groupMembersProvider(groupId)).valueOrNull ?? [];
          final currentMemberIds = currentMembers.map((m) => m.userId).toSet();

          // Filter out users who are already members
          final availableUsers = allUsers.where((user) => !currentMemberIds.contains(user.id)).toList();

          return AlertDialog(
            title: const Text('Add Members'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  // Search field
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) {
                      // Trigger rebuild to filter results
                      (context as Element).markNeedsBuild();
                    },
                  ),
                  const SizedBox(height: 16),
                  // User list
                  Expanded(
                    child: availableUsers.isEmpty
                        ? const Center(
                            child: Text('All users are already members'),
                          )
                        : ListView.builder(
                            itemCount: availableUsers.length,
                            itemBuilder: (context, index) {
                              final user = availableUsers[index];
                              final searchQuery = searchController.text.toLowerCase();

                              // Filter by search query
                              if (searchQuery.isNotEmpty &&
                                  !user.name.toLowerCase().contains(searchQuery)) {
                                return const SizedBox.shrink();
                              }

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: user.profileImage.isNotEmpty
                                      ? NetworkImage(user.profileImage)
                                      : null,
                                  child: user.profileImage.isEmpty
                                      ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U')
                                      : null,
                                ),
                                title: Text(user.name),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.add_circle,
                                    color: modernTheme.successColor,
                                  ),
                                  onPressed: () async {
                                    try {
                                      await ref
                                          .read(groupMembersProvider(groupId).notifier)
                                          .addMembers([user.id]);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                              content: Text('${user.name} added to group')),
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
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  searchController.dispose();
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRemoveMemberDialog(
      BuildContext context, WidgetRef ref, member) {
    final modernTheme = context.modernTheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove ${member.displayName} from the group?',
        ),
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
                    .removeMember(member.userId);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${member.displayName} removed')),
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
