// lib/features/groups/widgets/group_chat_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/groups/models/group_model.dart';
import 'package:textgb/features/groups/providers/group_provider.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

class GroupChatAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final GroupModel group;
  final VoidCallback onBack;

  const GroupChatAppBar({
    Key? key,
    required this.group,
    required this.onBack,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 0.5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modernTheme = context.modernTheme;
    
    // Simply watch the group provider - Riverpod handles caching automatically
    final groupState = ref.watch(groupProvider);
    
    // Use updated group data if available, otherwise use the passed group
    final currentGroup = groupState.valueOrNull?.currentGroup ?? group;
    final groupMembers = groupState.valueOrNull?.currentGroupMembers ?? [];
    
    // Get current user for admin check
    final currentUser = ref.watch(currentUserProvider);
    
    return AppBar(
      elevation: 0,
      backgroundColor: modernTheme.backgroundColor,
      leading: AppBarBackButton(onPressed: onBack),
      titleSpacing: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(
          height: 0.5,
          width: double.infinity,
          color: modernTheme.dividerColor,
        ),
      ),
      title: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            Constants.groupInformationScreen,
            arguments: currentGroup,
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            children: [
              // Group profile image
              Hero(
                tag: 'group_image_${currentGroup.groupId}',
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: modernTheme.primaryColor?.withOpacity(0.2),
                      child: currentGroup.groupImage.isNotEmpty
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: currentGroup.groupImage,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 40,
                                  height: 40,
                                  color: modernTheme.primaryColor?.withOpacity(0.1),
                                  child: const SizedBox.shrink(), // Don't show icon while loading
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  Icons.group,
                                  color: modernTheme.primaryColor,
                                  size: 20,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.group,
                              color: modernTheme.primaryColor,
                              size: 20,
                            ),
                    ),
                    // Group type indicator
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: modernTheme.backgroundColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: modernTheme.backgroundColor!,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          currentGroup.isPrivate ? Icons.lock : Icons.public,
                          size: 8,
                          color: currentGroup.isPrivate 
                              ? Colors.orange 
                              : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              
              // Group info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Group name with admin badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            currentGroup.groupName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: modernTheme.textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Simple admin badge check using existing group data
                        if (currentUser != null && currentGroup.isAdmin(currentUser.uid))
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: modernTheme.primaryColor?.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'ADMIN',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: modernTheme.primaryColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    // Members count - only show when we have real data
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        Expanded(
                          child: () {
                            final memberCountText = _getMemberCountText(
                              groupMembers, 
                              currentGroup, 
                              groupState.isLoading,
                            );
                            
                            // Only show member count if we have real data
                            if (memberCountText != null) {
                              return Text(
                                memberCountText,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: modernTheme.textSecondaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            }
                            
                            // Show nothing while waiting for real data
                            return const SizedBox.shrink();
                          }(),
                        ),
                        // Only show encryption indicator when we have member data
                        if (_getMemberCountText(groupMembers, currentGroup, groupState.isLoading) != null)
                          Icon(
                            Icons.lock_outline,
                            size: 12,
                            color: modernTheme.textSecondaryColor?.withOpacity(0.6),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: modernTheme.textSecondaryColor,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) => _handleMenuAction(context, ref, value, currentGroup, currentUser),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'info',
              child: _buildMenuItem(
                icon: Icons.info_outline,
                title: 'Group Info',
                modernTheme: modernTheme,
              ),
            ),
            PopupMenuItem(
              value: 'search',
              child: _buildMenuItem(
                icon: Icons.search,
                title: 'Search Messages',
                modernTheme: modernTheme,
              ),
            ),
            PopupMenuItem(
              value: 'mute',
              child: _buildMenuItem(
                icon: Icons.notifications_off_outlined,
                title: 'Mute Notifications',
                modernTheme: modernTheme,
              ),
            ),
            PopupMenuItem(
              value: 'media',
              child: _buildMenuItem(
                icon: Icons.photo_library_outlined,
                title: 'Media & Files',
                modernTheme: modernTheme,
              ),
            ),
            const PopupMenuDivider(),
            // Only show admin options if user is admin
            if (currentUser != null && currentGroup.isAdmin(currentUser.uid)) ...[
              PopupMenuItem(
                value: 'settings',
                child: _buildMenuItem(
                  icon: Icons.settings_outlined,
                  title: 'Group Settings',
                  modernTheme: modernTheme,
                ),
              ),
              if (currentGroup.awaitingApprovalUIDs.isNotEmpty)
                PopupMenuItem(
                  value: 'requests',
                  child: _buildMenuItem(
                    icon: Icons.person_add_outlined,
                    title: 'Pending Requests (${currentGroup.awaitingApprovalUIDs.length})',
                    modernTheme: modernTheme,
                  ),
                ),
              const PopupMenuDivider(),
            ],
            PopupMenuItem(
              value: 'leave',
              child: _buildMenuItem(
                icon: Icons.exit_to_app,
                title: 'Leave Group',
                modernTheme: modernTheme,
                isDestructive: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Simple helper to get member count text - only show real data
  String? _getMemberCountText(List groupMembers, GroupModel group, bool isLoading) {
    // Don't show anything while loading
    if (isLoading && groupMembers.isEmpty && group.membersUIDs.isEmpty) {
      return null;
    }
    
    // Use fresh member data if available, otherwise use group data
    final memberCount = groupMembers.isNotEmpty ? groupMembers.length : group.membersUIDs.length;
    
    // Only show count if we have actual data
    if (memberCount == 0) {
      return null; // Don't show "No members" - wait for real data
    } else if (memberCount == 1) {
      return '1 member';
    } else {
      return '$memberCount members';
    }
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required ModernThemeExtension modernTheme,
    bool isDestructive = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDestructive 
              ? Colors.red 
              : modernTheme.textSecondaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: isDestructive 
                  ? Colors.red 
                  : modernTheme.textColor,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    GroupModel group,
    currentUser,
  ) async {
    switch (action) {
      case 'info':
        Navigator.pushNamed(
          context,
          Constants.groupInformationScreen,
          arguments: group,
        );
        break;
        
      case 'search':
        showSnackBar(context, 'Message search coming soon');
        break;
        
      case 'mute':
        showSnackBar(context, 'Mute notifications coming soon');
        break;
        
      case 'media':
        showSnackBar(context, 'Media gallery coming soon');
        break;
        
      case 'settings':
        Navigator.pushNamed(
          context,
          Constants.groupSettingsScreen,
          arguments: group,
        );
        break;
        
      case 'requests':
        Navigator.pushNamed(
          context,
          Constants.pendingRequestsScreen,
          arguments: group,
        );
        break;
        
      case 'leave':
        _showLeaveGroupDialog(context, ref, group);
        break;
    }
  }

  void _showLeaveGroupDialog(
    BuildContext context,
    WidgetRef ref,
    GroupModel group,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.exit_to_app,
              color: Colors.red,
            ),
            const SizedBox(width: 8),
            const Text('Leave Group'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to leave "${group.groupName}"?'),
            const SizedBox(height: 8),
            Text(
              'You will no longer receive messages from this group.',
              style: TextStyle(
                fontSize: 12,
                color: context.modernTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(groupProvider.notifier).leaveGroup(group.groupId);
                if (context.mounted) {
                  Navigator.pop(context);
                  showSnackBar(context, 'You left the group');
                }
              } catch (e) {
                if (context.mounted) {
                  showSnackBar(context, 'Error leaving group: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}