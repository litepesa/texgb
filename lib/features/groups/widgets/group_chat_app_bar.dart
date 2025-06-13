// lib/features/groups/widgets/group_chat_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/groups/models/group_model.dart';
import 'package:textgb/features/groups/providers/group_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';
import 'package:textgb/models/user_model.dart';

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
    final groupState = ref.watch(groupProvider);
    
    // Use the initial group data immediately, then update with fresh data when available
    final currentGroup = groupState.valueOrNull?.currentGroup ?? group;
    final groupMembers = groupState.valueOrNull?.currentGroupMembers ?? [];
    
    // Pre-load group details in the background without blocking UI
    ref.listen(groupProvider, (previous, next) {
      // This listener ensures fresh data is loaded but doesn't block initial render
    });
    
    // Trigger background refresh if we don't have current group data
    if (groupState.valueOrNull?.currentGroup?.groupId != group.groupId) {
      // Load fresh data in background without waiting
      Future.microtask(() {
        ref.read(groupProvider.notifier).getGroupDetails(group.groupId);
      });
    }
    
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
          // Navigate to group info screen when tapping on title area
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
              // Group profile image with cached loading and immediate fallback
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
                                cacheManager: CacheManager(
                                  Config(
                                    'group_images',
                                    stalePeriod: const Duration(days: 7),
                                    maxNrOfCacheObjects: 100,
                                  ),
                                ),
                                placeholder: (context, url) => Icon(
                                  Icons.group,
                                  color: modernTheme.primaryColor,
                                  size: 20,
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  Icons.group,
                                  color: modernTheme.primaryColor,
                                  size: 20,
                                ),
                                fadeInDuration: const Duration(milliseconds: 150),
                                fadeOutDuration: const Duration(milliseconds: 150),
                              ),
                            )
                          : Icon(
                              Icons.group,
                              color: modernTheme.primaryColor,
                              size: 20,
                            ),
                    ),
                    // Group type indicator (private/public)
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
              
              // Group info with smart member count display
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Group name with typing indicator space
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
                        // Admin badge if user is admin (cached check)
                        _buildAdminBadge(ref, currentGroup, modernTheme),
                      ],
                    ),
                    
                    // Members count and status with smart loading
                    const SizedBox(height: 1),
                    _buildGroupSubtitle(context, currentGroup, groupMembers, modernTheme, groupState.isLoading),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // More options menu
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: modernTheme.textSecondaryColor,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) => _handleMenuAction(context, ref, value, currentGroup),
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

  // Cached admin badge check with immediate display
  Widget _buildAdminBadge(WidgetRef ref, GroupModel group, ModernThemeExtension modernTheme) {
    return FutureBuilder<bool>(
      future: ref.read(groupProvider.notifier).isCurrentUserAdmin(group.groupId),
      builder: (context, snapshot) {
        // Show cached result immediately if available
        if (snapshot.hasData && snapshot.data == true) {
          return Container(
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
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // Smart subtitle that shows immediate info and updates progressively
  Widget _buildGroupSubtitle(
    BuildContext context,
    GroupModel group,
    List groupMembers,
    ModernThemeExtension modernTheme,
    bool isLoading,
  ) {
    // Use immediate data from group model, then enhance with fresh data
    final memberCount = groupMembers.isNotEmpty ? groupMembers.length : group.membersUIDs.length;
    
    String subtitleText;
    if (memberCount == 0) {
      subtitleText = isLoading ? 'Loading...' : 'No members';
    } else if (memberCount == 1) {
      subtitleText = '1 member';
    } else {
      subtitleText = '$memberCount members';
    }
    
    return Row(
      children: [
        Expanded(
          child: Text(
            subtitleText,
            style: TextStyle(
              fontSize: 12,
              color: modernTheme.textSecondaryColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Add encryption indicator
        Icon(
          Icons.lock_outline,
          size: 12,
          color: modernTheme.textSecondaryColor?.withOpacity(0.6),
        ),
      ],
    );
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
        // TODO: Implement message search
        showSnackBar(context, 'Message search coming soon');
        break;
        
      case 'mute':
        // TODO: Implement mute notifications
        showSnackBar(context, 'Mute notifications coming soon');
        break;
        
      case 'media':
        // TODO: Navigate to media gallery
        showSnackBar(context, 'Media gallery coming soon');
        break;
        
      case 'settings':
        final isAdmin = await ref.read(groupProvider.notifier)
            .isCurrentUserAdmin(group.groupId);
        if (isAdmin) {
          Navigator.pushNamed(
            context,
            Constants.groupSettingsScreen,
            arguments: group,
          );
        } else {
          showSnackBar(context, 'Only admins can access group settings');
        }
        break;
        
      case 'requests':
        final isAdmin = await ref.read(groupProvider.notifier)
            .isCurrentUserAdmin(group.groupId);
        if (isAdmin && group.awaitingApprovalUIDs.isNotEmpty) {
          Navigator.pushNamed(
            context,
            Constants.pendingRequestsScreen,
            arguments: group,
          );
        } else if (!isAdmin) {
          showSnackBar(context, 'Only admins can view pending requests');
        } else {
          showSnackBar(context, 'No pending requests');
        }
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
                  Navigator.pop(context); // Return to groups list
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