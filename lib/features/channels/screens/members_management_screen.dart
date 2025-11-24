// lib/features/channels/screens/members_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/channels/models/channel_model.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';

/// Screen for managing channel members (admins/moderators)
class MembersManagementScreen extends ConsumerStatefulWidget {
  final String channelId;

  const MembersManagementScreen({
    super.key,
    required this.channelId,
  });

  @override
  ConsumerState<MembersManagementScreen> createState() =>
      _MembersManagementScreenState();
}

class _MembersManagementScreenState
    extends ConsumerState<MembersManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(channelMembersProvider(widget.channelId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Members'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showMemberLimitsInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search members...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Members List
          Expanded(
            child: membersAsync.when(
              data: (members) {
                if (members.isEmpty) {
                  return _buildEmptyState();
                }

                // Filter members by search
                final filteredMembers = _searchQuery.isEmpty
                    ? members
                    : members.where((member) {
                        return member.userName
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()) ||
                            member.role.name
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase());
                      }).toList();

                // Group by role
                final owners = filteredMembers
                    .where((m) => m.role == MemberRole.owner)
                    .toList();
                final admins = filteredMembers
                    .where((m) => m.role == MemberRole.admin)
                    .toList();
                final moderators = filteredMembers
                    .where((m) => m.role == MemberRole.moderator)
                    .toList();

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(channelMembersProvider(widget.channelId));
                  },
                  child: ListView(
                    children: [
                      // Member Count Summary
                      _buildSummaryCard(
                        totalMembers: members.length,
                        maxMembers: 8,
                        admins: admins.length,
                        moderators: moderators.length,
                      ),

                      // Owner Section
                      if (owners.isNotEmpty) ...[
                        _buildSectionHeader('Owner', owners.length),
                        ...owners.map((member) => _buildMemberTile(member)),
                      ],

                      // Admins Section
                      if (admins.isNotEmpty) ...[
                        _buildSectionHeader('Admins', admins.length),
                        ...admins.map((member) => _buildMemberTile(member)),
                      ],

                      // Moderators Section
                      if (moderators.isNotEmpty) ...[
                        _buildSectionHeader('Moderators', moderators.length),
                        ...moderators.map((member) => _buildMemberTile(member)),
                      ],

                      if (filteredMembers.isEmpty && _searchQuery.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text('No members found'),
                          ),
                        ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(error.toString()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMemberDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Member'),
      ),
    );
  }

  Widget _buildSummaryCard({
    required int totalMembers,
    required int maxMembers,
    required int admins,
    required int moderators,
  }) {
    final spotsLeft = maxMembers - totalMembers;
    final isAtLimit = totalMembers >= maxMembers;

    return Card(
      margin: const EdgeInsets.all(16),
      color: isAtLimit ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Members: $totalMembers / $maxMembers',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  isAtLimit ? Icons.warning : Icons.info_outline,
                  color: isAtLimit ? Colors.orange : Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: totalMembers / maxMembers,
              backgroundColor: Colors.grey[300],
              color: isAtLimit ? Colors.orange : Colors.blue,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatChip('Admins', admins, Colors.purple),
                const SizedBox(width: 8),
                _buildStatChip('Moderators', moderators, Colors.green),
              ],
            ),
            if (isAtLimit) ...[
              const SizedBox(height: 8),
              Text(
                'Member limit reached. Remove a member to add a new one.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange[800],
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                '$spotsLeft spot${spotsLeft == 1 ? '' : 's'} remaining',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        '$title ($count)',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildMemberTile(ChannelMember member) {
    final roleColor = _getRoleColor(member.role);
    final isOwner = member.role == MemberRole.owner;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: member.userAvatarUrl != null
            ? NetworkImage(member.userAvatarUrl!)
            : null,
        child: member.userAvatarUrl == null
            ? const Icon(Icons.person)
            : null,
      ),
      title: Text(member.userName),
      subtitle: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: roleColor),
            ),
            child: Text(
              _getRoleName(member.role),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: roleColor,
              ),
            ),
          ),
          if (member.addedAt != null) ...[
            const SizedBox(width: 8),
            Text(
              'Added ${_timeAgo(member.addedAt!)}',
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ],
      ),
      trailing: isOwner
          ? null
          : PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'change_role') {
                  _showChangeRoleDialog(member);
                } else if (value == 'remove') {
                  _confirmRemoveMember(member);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'change_role',
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz, size: 20),
                      SizedBox(width: 8),
                      Text('Change Role'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.remove_circle, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Remove', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No team members yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add admins and moderators to help manage your channel',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load members',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(channelMembersProvider(widget.channelId));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMemberLimitsInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Member Limits'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Channels can have up to 8 team members (excluding owner):',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),
            Text('• 1 Owner (you)'),
            Text('• Up to 8 Admins and/or Moderators'),
            SizedBox(height: 12),
            Text('Admins can:'),
            Text('  - Manage posts'),
            Text('  - Moderate comments'),
            Text('  - Add/remove moderators'),
            SizedBox(height: 8),
            Text('Moderators can:'),
            Text('  - Moderate comments'),
            Text('  - Pin/unpin comments'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddMemberDialog(BuildContext context) async {
    // Check if at limit
    final members = await ref.read(channelMembersProvider(widget.channelId).future);
    if (members.length >= 8) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member limit reached (8 members max)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    final userIdController = TextEditingController();
    MemberRole selectedRole = MemberRole.moderator;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: userIdController,
                decoration: const InputDecoration(
                  labelText: 'User ID',
                  hintText: 'Enter user ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MemberRole>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: MemberRole.admin,
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings,
                            color: _getRoleColor(MemberRole.admin)),
                        const SizedBox(width: 8),
                        const Text('Admin'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: MemberRole.moderator,
                    child: Row(
                      children: [
                        Icon(Icons.shield,
                            color: _getRoleColor(MemberRole.moderator)),
                        const SizedBox(width: 8),
                        const Text('Moderator'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedRole = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (userIdController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter user ID')),
                  );
                  return;
                }

                Navigator.pop(dialogContext);
                await _addMember(userIdController.text.trim(), selectedRole);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addMember(String userId, MemberRole role) async {
    final actionsNotifier = ref.read(channelMemberActionsProvider.notifier);
    final success = await actionsNotifier.addMember(
      channelId: widget.channelId,
      userId: userId,
      role: role,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Member added successfully!' : 'Failed to add member',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showChangeRoleDialog(ChannelMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change role for ${member.userName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.admin_panel_settings,
                  color: _getRoleColor(MemberRole.admin)),
              title: const Text('Admin'),
              onTap: () {
                Navigator.pop(context);
                _changeRole(member, MemberRole.admin);
              },
            ),
            ListTile(
              leading: Icon(Icons.shield,
                  color: _getRoleColor(MemberRole.moderator)),
              title: const Text('Moderator'),
              onTap: () {
                Navigator.pop(context);
                _changeRole(member, MemberRole.moderator);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeRole(ChannelMember member, MemberRole newRole) async {
    // Remove old role and add new role
    final actionsNotifier = ref.read(channelMemberActionsProvider.notifier);

    await actionsNotifier.removeMember(
      channelId: widget.channelId,
      userId: member.userId,
    );

    final success = await actionsNotifier.addMember(
      channelId: widget.channelId,
      userId: member.userId,
      role: newRole,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Role changed successfully!' : 'Failed to change role',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmRemoveMember(ChannelMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${member.userName}?'),
        content: const Text(
          'This member will lose access to channel management features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _removeMember(member);
    }
  }

  Future<void> _removeMember(ChannelMember member) async {
    final actionsNotifier = ref.read(channelMemberActionsProvider.notifier);
    final success = await actionsNotifier.removeMember(
      channelId: widget.channelId,
      userId: member.userId,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Member removed successfully!' : 'Failed to remove member',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Color _getRoleColor(MemberRole role) {
    switch (role) {
      case MemberRole.owner:
        return Colors.amber;
      case MemberRole.admin:
        return Colors.purple;
      case MemberRole.moderator:
        return Colors.green;
      case MemberRole.subscriber:
        return Colors.blue;
    }
  }

  String _getRoleName(MemberRole role) {
    switch (role) {
      case MemberRole.owner:
        return 'Owner';
      case MemberRole.admin:
        return 'Admin';
      case MemberRole.moderator:
        return 'Moderator';
      case MemberRole.subscriber:
        return 'Subscriber';
    }
  }

  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}
