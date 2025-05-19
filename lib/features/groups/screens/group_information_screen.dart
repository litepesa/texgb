// lib/features/groups/screens/group_information_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/groups/models/group_model.dart';
import 'package:textgb/features/groups/providers/group_provider.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

class GroupInformationScreen extends ConsumerStatefulWidget {
  final GroupModel group;

  const GroupInformationScreen({
    super.key,
    required this.group,
  });

  @override
  ConsumerState<GroupInformationScreen> createState() => _GroupInformationScreenState();
}

class _GroupInformationScreenState extends ConsumerState<GroupInformationScreen> {
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    // Load group details when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroupDetails();
    });
  }

  Future<void> _loadGroupDetails() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await ref.read(groupProvider.notifier).getGroupDetails(widget.group.groupId);
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error loading group details: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openGroupChat() {
    final group = ref.read(groupProvider).value?.currentGroup ?? widget.group;
    ref.read(groupProvider.notifier).openGroupChat(group, context);
  }

  void _showLeaveGroupDialog() {
    showMyAnimatedDialog(
      context: context,
      title: 'Leave Group',
      content: 'Are you sure you want to leave this group?',
      textAction: 'Leave',
      onActionTap: (confirmed) {
        if (confirmed) {
          _leaveGroup();
        }
      },
    );
  }

  Future<void> _leaveGroup() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await ref.read(groupProvider.notifier).leaveGroup(widget.group.groupId);
      if (mounted) {
        showSnackBar(context, 'You left the group');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error leaving group: $e');
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
    final theme = context.modernTheme;
    final groupAsync = ref.watch(groupProvider);
    
    final group = groupAsync.value?.currentGroup ?? widget.group;
    final members = groupAsync.value?.currentGroupMembers ?? [];
    
    final isAdmin = ref.read(groupProvider.notifier).isCurrentUserAdmin(group.groupId);
    final isCreator = ref.read(groupProvider.notifier).isCurrentUserCreator(group.groupId);
    
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        title: Text(
          'Group Info',
          style: TextStyle(color: theme.textColor),
        ),
        leading: AppBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isAdmin)
            IconButton(
              icon: Icon(
                Icons.edit,
                color: theme.primaryColor,
              ),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  Constants.groupSettingsScreen,
                  arguments: group,
                );
              },
            ),
        ],
        elevation: 0,
      ),
      body: _isLoading || groupAsync.isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group image and name
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: theme.primaryColor!.withOpacity(0.2),
                          backgroundImage: group.groupImage.isNotEmpty
                              ? NetworkImage(group.groupImage)
                              : null,
                          child: group.groupImage.isEmpty
                              ? Icon(
                                  Icons.group,
                                  size: 40,
                                  color: theme.primaryColor,
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.groupName,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${group.membersUIDs.length} members',
                                style: TextStyle(
                                  color: theme.textSecondaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (isCreator)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.primaryColor!.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Creator',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.primaryColor,
                                        ),
                                      ),
                                    )
                                  else if (isAdmin)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      // lib/features/groups/screens/group_information_screen.dart (continued)
                                      decoration: BoxDecoration(
                                        color: theme.primaryColor!.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Admin',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.primaryColor,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.surfaceVariantColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      group.isPrivate ? 'Private' : 'Public',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.textSecondaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Description
                  if (group.groupDescription.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Card(
                        elevation: 0,
                        color: theme.surfaceColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: theme.borderColor!.withOpacity(0.2),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Description',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                group.groupDescription,
                                style: TextStyle(
                                  color: theme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.chat),
                            label: const Text('Open Chat'),
                            onPressed: _openGroupChat,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.exit_to_app),
                          label: const Text('Leave'),
                          onPressed: _showLeaveGroupDialog,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Members section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Members',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                            if (isAdmin)
                              TextButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Add'),
                                onPressed: () {
                                  // TODO: Navigate to add members screen
                                },
                              ),
                          ],
                        ),
                        if (group.awaitingApprovalUIDs.isNotEmpty && isAdmin)
                          _buildAwaitingApprovalSection(group),
                        const SizedBox(height: 8),
                        if (members.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(
                                color: theme.primaryColor,
                              ),
                            ),
                          )
                        else
                          _buildMembersList(members, group, isAdmin, isCreator),
                      ],
                    ),
                  ),
                  
                  // Group Settings section
                  if (isAdmin)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 0,
                        color: theme.surfaceColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: theme.borderColor!.withOpacity(0.2),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Group Settings',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildSettingItem(
                                icon: Icons.public,
                                title: 'Group Type',
                                value: group.isPrivate ? 'Private' : 'Public',
                              ),
                              _buildSettingItem(
                                icon: Icons.admin_panel_settings,
                                title: 'Admin-only Settings',
                                value: group.editSettings ? 'Yes' : 'No',
                              ),
                              if (group.isPrivate)
                                _buildSettingItem(
                                  icon: Icons.approval,
                                  title: 'Approve Members',
                                  value: group.approveMembers ? 'Yes' : 'No',
                                ),
                              _buildSettingItem(
                                icon: Icons.lock,
                                title: 'Lock Messages',
                                value: group.lockMessages ? 'Yes' : 'No',
                              ),
                              if (!group.isPrivate)
                                _buildSettingItem(
                                  icon: Icons.person_add,
                                  title: 'Request to Join',
                                  value: group.requestToJoin ? 'Yes' : 'No',
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  // Build awaiting approval section
  Widget _buildAwaitingApprovalSection(GroupModel group) {
    final theme = context.modernTheme;
    
    return Card(
      elevation: 0,
      color: theme.primaryColor!.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Awaiting Approval (${group.awaitingApprovalUIDs.length})',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Users have requested to join this group. As an admin, you can approve or reject their requests.',
              style: TextStyle(
                color: theme.textSecondaryColor,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // TODO: Navigate to pending requests screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('View Requests'),
            ),
          ],
        ),
      ),
    );
  }

  // Build members list
  Widget _buildMembersList(
    List<UserModel> members,
    GroupModel group,
    bool isAdmin,
    bool isCreator,
  ) {
    final theme = context.modernTheme;
    final currentUser = ref.read(currentUserProvider);
    
    // Sort members: creator first, then admins, then other members
    members.sort((a, b) {
      if (a.uid == group.creatorUID) return -1;
      if (b.uid == group.creatorUID) return 1;
      if (group.adminsUIDs.contains(a.uid) && !group.adminsUIDs.contains(b.uid)) return -1;
      if (!group.adminsUIDs.contains(a.uid) && group.adminsUIDs.contains(b.uid)) return 1;
      return a.name.compareTo(b.name);
    });
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final isCreatorUser = member.uid == group.creatorUID;
        final isAdminUser = group.adminsUIDs.contains(member.uid);
        final isSelf = currentUser?.uid == member.uid;
        
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: member.image.isNotEmpty
                ? NetworkImage(member.image)
                : null,
            backgroundColor: theme.primaryColor!.withOpacity(0.2),
            child: member.image.isEmpty
                ? Text(
                    member.name[0].toUpperCase(),
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  member.name,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: isSelf ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelf)
                Text(
                  'You',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textSecondaryColor,
                  ),
                ),
            ],
          ),
          subtitle: Row(
            children: [
              if (isCreatorUser)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor!.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Creator',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.primaryColor,
                    ),
                  ),
                )
              else if (isAdminUser)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor!.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Admin',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  member.phoneNumber,
                  style: TextStyle(
                    color: theme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          trailing: (isAdmin && !isSelf && !isCreatorUser)
              ? PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: theme.textSecondaryColor,
                  ),
                  onSelected: (value) {
                    _handleMemberAction(value, member, group);
                  },
                  itemBuilder: (context) => [
                    if (!isAdminUser)
                      const PopupMenuItem(
                        value: 'make_admin',
                        child: Text('Make Admin'),
                      )
                    else if (isCreator)
                      const PopupMenuItem(
                        value: 'remove_admin',
                        child: Text('Remove Admin'),
                      ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove from Group'),
                    ),
                  ],
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        );
      },
    );
  }

  // Build setting item
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    final theme = context.modernTheme;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.primaryColor,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: theme.textColor,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: theme.textSecondaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Handle member action
  void _handleMemberAction(String action, UserModel member, GroupModel group) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      switch (action) {
        case 'make_admin':
          await ref.read(groupProvider.notifier).addAdmin(group.groupId, member.uid);
          if (mounted) {
            showSnackBar(context, '${member.name} is now an admin');
          }
          break;
        case 'remove_admin':
          await ref.read(groupProvider.notifier).removeAdmin(group.groupId, member.uid);
          if (mounted) {
            showSnackBar(context, '${member.name} is no longer an admin');
          }
          break;
        case 'remove':
          await ref.read(groupProvider.notifier).removeMember(group.groupId, member.uid);
          if (mounted) {
            showSnackBar(context, '${member.name} has been removed from the group');
          }
          break;
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}