// lib/features/groups/screens/group_information_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    
    // Check if the current user is a member before opening the chat
    final isMember = ref.read(groupProvider.notifier).isCurrentUserMember(group.groupId);
    
    if (!isMember) {
      // Show join dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Join Group'),
          content: const Text('You need to be a member to view and send messages in this group. Would you like to join?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ref.read(groupProvider.notifier).joinGroup(group.groupId);
                  if (mounted) {
                    showSnackBar(context, 'You have joined the group');
                    // Open chat after joining
                    ref.read(groupProvider.notifier).openGroupChat(group, context);
                  }
                } catch (e) {
                  if (mounted) {
                    showSnackBar(context, 'Error joining group: $e');
                  }
                }
              },
              child: const Text('Join Group'),
            ),
          ],
        ),
      );
      return;
    }
    
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
  
  void _shareGroupLink() async {
    try {
      final group = ref.read(groupProvider).value?.currentGroup ?? widget.group;
      final joinCode = group.getJoiningCode();
      
      // Check if group is near member limit before sharing
      final remainingSlots = GroupModel.MAX_MEMBERS - group.membersUIDs.length;
      if (remainingSlots <= 10) {
        // Show warning dialog first
        final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Group Nearly Full'),
            content: Text(
              'This group has only $remainingSlots ${remainingSlots == 1 ? 'slot' : 'slots'} '
              'remaining out of ${GroupModel.MAX_MEMBERS}. Do you still want to share the invite link?'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Continue Sharing'),
              ),
            ],
          ),
        );
        
        if (shouldContinue != true) {
          return;
        }
      }
      
      // Share the join code and a message
      final shareText = 'Join my group "${group.groupName}" on TextGB! Use this code: $joinCode';
      
      // Show dialog with the code
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Share Group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Share this group code with friends:'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: context.modernTheme.surfaceVariantColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      joinCode,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () async {
                        // Copy to clipboard
                        await Clipboard.setData(ClipboardData(text: joinCode));
                        if (context.mounted) {
                          Navigator.pop(context);
                          showSnackBar(context, 'Group code copied to clipboard');
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Or share this message:',
                style: TextStyle(
                  color: context.modernTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                shareText,
                style: TextStyle(
                  color: context.modernTheme.textColor,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: shareText));
                if (context.mounted) {
                  Navigator.pop(context);
                  showSnackBar(context, 'Share message copied to clipboard');
                }
              },
              child: const Text('Copy Message'),
            ),
          ],
        ),
      );
    } catch (e) {
      showSnackBar(context, 'Error sharing group link: $e');
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
    final isMember = ref.read(groupProvider.notifier).isCurrentUserMember(group.groupId);
    
    // Calculate member stats
    final memberPercentage = group.getMemberCapacityPercentage();
    final isNearCapacity = memberPercentage > 0.9; // 90% full
    final isAtCapacity = group.hasReachedMemberLimit();
    final remainingSlots = group.getRemainingMemberSlots();
    
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
          if (isMember)
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share Group',
              onPressed: _shareGroupLink,
            ),
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
                                group.getMemberCountWithLimit(),
                                style: TextStyle(
                                  color: isAtCapacity
                                      ? Colors.red
                                      : (isNearCapacity
                                          ? Colors.orange
                                          : theme.textSecondaryColor),
                                  fontWeight: isNearCapacity ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Member capacity progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: memberPercentage,
                                  backgroundColor: theme.surfaceVariantColor,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isAtCapacity
                                        ? Colors.red
                                        : (isNearCapacity
                                            ? Colors.orange
                                            : theme.primaryColor!),
                                  ),
                                  minHeight: 6,
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
                                  if (isMember)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Member',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green,
                                          ),
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
                  
                  // Member capacity info card (when near capacity)
                  if (isNearCapacity)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Card(
                        elevation: 0,
                        color: isAtCapacity
                            ? Colors.red.shade50
                            : Colors.orange.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isAtCapacity
                                ? Colors.red.shade200
                                : Colors.orange.shade200,
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Icon(
                                isAtCapacity
                                    ? Icons.error_outline
                                    : Icons.warning_amber_rounded,
                                color: isAtCapacity
                                    ? Colors.red
                                    : Colors.orange,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isAtCapacity
                                          ? 'Member Limit Reached'
                                          : 'Group Almost Full',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isAtCapacity
                                            ? Colors.red
                                            : Colors.orange.shade800,
                                      ),
                                    ),
                                    Text(
                                      isAtCapacity
                                          ? 'This group has reached the maximum of ${GroupModel.MAX_MEMBERS} members.'
                                          : 'Only $remainingSlots ${remainingSlots == 1 ? 'slot' : 'slots'} remaining out of ${GroupModel.MAX_MEMBERS}.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isAtCapacity
                                            ? Colors.red.shade700
                                            : Colors.orange.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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
                            label: Text(isMember ? 'Open Chat' : 'Join Group'),
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
                        if (isMember) ...[
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
                            Row(
                              children: [
                                Text(
                                  'Members',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isAtCapacity
                                        ? Colors.red.withOpacity(0.2)
                                        : (isNearCapacity
                                            ? Colors.orange.withOpacity(0.2)
                                            : theme.surfaceVariantColor),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${group.membersUIDs.length}/${GroupModel.MAX_MEMBERS}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isAtCapacity
                                          ? Colors.red
                                          : (isNearCapacity
                                              ? Colors.orange
                                              : theme.textSecondaryColor),
                                      fontWeight: isNearCapacity ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (isAdmin && !isAtCapacity)
                              TextButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Add'),
                                onPressed: () {
                                  // Navigate to add members screen
                                  // TODO: Implement add members screen
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
                              _buildSettingItem(
                                icon: Icons.people,
                                title: 'Member Limit',
                                value: '${GroupModel.MAX_MEMBERS}',
                                valueColor: isNearCapacity
                                    ? (isAtCapacity ? Colors.red : Colors.orange)
                                    : null,
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
    final remainingSlots = group.getRemainingMemberSlots();
    final canApproveAll = remainingSlots >= group.awaitingApprovalUIDs.length;
    
    return Card(
      elevation: 0,
      color: canApproveAll
          ? theme.primaryColor!.withOpacity(0.1)
          : Colors.orange.shade50,
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
                color: canApproveAll
                    ? theme.primaryColor
                    : Colors.orange.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              canApproveAll
                  ? 'Users have requested to join this group. As an admin, you can approve or reject their requests.'
                  : 'Not enough slots to approve all pending requests. Only $remainingSlots ${remainingSlots == 1 ? 'slot' : 'slots'} remaining.',
              style: TextStyle(
                color: canApproveAll
                    ? theme.textSecondaryColor
                    : Colors.orange.shade700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // TODO: Navigate to pending requests screen
                Navigator.pushNamed(
                  context,
                  Constants.pendingRequestsScreen,
                  arguments: group,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: canApproveAll
                    ? theme.primaryColor
                    : Colors.orange,
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
    Color? valueColor,
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
              color: valueColor ?? theme.textSecondaryColor,
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
          // Show confirmation dialog
          final shouldRemove = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Remove Member'),
              content: Text('Are you sure you want to remove ${member.name} from the group?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: Text('Remove'),
                ),
              ],
            ),
          );
          
          if (shouldRemove == true) {
            await ref.read(groupProvider.notifier).removeMember(group.groupId, member.uid);
            if (mounted) {
              showSnackBar(context, '${member.name} has been removed from the group');
            }
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