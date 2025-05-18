// lib/features/groups/widgets/group_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/groups/models/group_model.dart';
import 'package:textgb/features/groups/providers/group_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class GroupTile extends ConsumerWidget {
  final GroupModel group;
  final VoidCallback onTap;

  const GroupTile({
    super.key,
    required this.group,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.modernTheme;
    final isAdmin = ref.read(groupProvider.notifier).isCurrentUserAdmin(group.groupId);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: theme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.borderColor!.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Group image
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
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
                              'Admin',
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
                          ? group.lastMessage
                          : group.groupDescription,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textSecondaryColor,
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
                          color: theme.textTertiaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${group.membersUIDs.length} members',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTertiaryColor,
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
                            color: theme.textTertiaryColor,
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