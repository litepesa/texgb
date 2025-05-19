// lib/features/groups/widgets/group_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/groups/models/group_model.dart';
import 'package:textgb/features/groups/providers/group_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class GroupTile extends ConsumerWidget {
  final GroupModel group;
  final VoidCallback? onTap;

  const GroupTile({
    super.key,
    required this.group,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.modernTheme;
    final isAdmin = ref.read(groupProvider.notifier).isCurrentUserAdmin(group.groupId);
    final isMember = ref.read(groupProvider.notifier).isCurrentUserMember(group.groupId);
    final isCreator = ref.read(groupProvider.notifier).isCurrentUserCreator(group.groupId);
    
    // Calculate unread messages for this group
    final unreadCount = group.getUnreadCountForUser(ref.read(groupProvider.notifier).getCurrentUserUid() ?? '');
    final hasUnread = unreadCount > 0;
    
    // Check if the group is near capacity
    final memberPercentage = group.getMemberCapacityPercentage();
    final isNearCapacity = memberPercentage > 0.9; // 90% full
    final isAtCapacity = group.hasReachedMemberLimit();
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: hasUnread ? theme.surfaceVariantColor?.withOpacity(0.3) : theme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isAtCapacity 
              ? Colors.red.withOpacity(0.5)
              : (isNearCapacity 
                  ? Colors.orange.withOpacity(0.5) 
                  : theme.borderColor!.withOpacity(0.2)),
          width: isAtCapacity || isNearCapacity ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Group image with membership indicator
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.primaryColor!.withOpacity(0.2),
                    backgroundImage: group.groupImage.isNotEmpty
                        ? NetworkImage(group.groupImage)
                        : null,
                    child: group.groupImage.isEmpty
                        ? Icon(
                            Icons.group,
                            color: theme.primaryColor,
                            size: 24,
                          )
                        : null,
                  ),
                  if (isMember)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.backgroundColor!, width: 1.5),
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: theme.primaryColor,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Group info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.groupName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                              color: theme.textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Admin badge
                        if (isAdmin)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primaryColor!.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isCreator ? 'Creator' : 'Admin',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.primaryColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      group.lastMessage.isNotEmpty
                          ? group.getLastMessagePreview()
                          : group.groupDescription,
                      style: TextStyle(
                        fontSize: 14,
                        color: hasUnread ? theme.textColor : theme.textSecondaryColor,
                        fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 14,
                          color: isAtCapacity 
                              ? Colors.red
                              : (isNearCapacity 
                                  ? Colors.orange 
                                  : theme.textTertiaryColor),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${group.membersUIDs.length}/${GroupModel.MAX_MEMBERS}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isAtCapacity 
                                ? Colors.red
                                : (isNearCapacity 
                                    ? Colors.orange 
                                    : theme.textTertiaryColor),
                            fontWeight: isNearCapacity ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        // Show capacity indicator if near limit
                        if (isNearCapacity)
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Icon(
                              isAtCapacity ? Icons.error_outline : Icons.warning_amber_rounded,
                              size: 14,
                              color: isAtCapacity ? Colors.red : Colors.orange,
                            ),
                          ),
                        const Spacer(),
                        // Last message time or creation date
                        Text(
                          _formatTime(group.lastMessageTime.isNotEmpty
                              ? group.lastMessageTime
                              : group.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: hasUnread ? theme.primaryColor : theme.textTertiaryColor,
                          ),
                        ),
                        // Add unread count badge to the right
                        if (hasUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              shape: unreadCount > 99 
                                  ? BoxShape.rectangle 
                                  : BoxShape.circle,
                              borderRadius: unreadCount > 99 
                                  ? BorderRadius.circular(10) 
                                  : null,
                            ),
                            constraints: BoxConstraints(
                              minWidth: unreadCount > 99 ? 32 : 24,
                              minHeight: 24,
                            ),
                            child: Center(
                              child: Text(
                                unreadCount > 99 
                                    ? '99+' 
                                    : unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    // Group capacity progress bar for groups near capacity
                    if (memberPercentage > 0.7) // Show progress bar when over 70% full
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: memberPercentage,
                              backgroundColor: theme.surfaceVariantColor?.withOpacity(0.5),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isAtCapacity 
                                    ? Colors.red 
                                    : (isNearCapacity 
                                        ? Colors.orange 
                                        : theme.primaryColor!),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String timeString) {
    if (timeString.isEmpty) return '';
    
    final timestamp = int.tryParse(timeString);
    if (timestamp == null) return '';
    
    final messageTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(messageTime);
    
    if (difference.inDays > 7) {
      // If more than a week, show date
      return '${messageTime.day}/${messageTime.month}/${messageTime.year}';
    } else if (difference.inDays > 0) {
      // If more than a day, show days ago
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      // If more than an hour, show hours ago
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      // If more than a minute, show minutes ago
      return '${difference.inMinutes}m ago';
    } else {
      // Otherwise, show "just now"
      return 'Just now';
    }
  }
}