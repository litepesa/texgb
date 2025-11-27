// lib/features/groups/widgets/group_tile.dart
import 'package:flutter/material.dart';
import 'package:textgb/features/groups/models/group_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class GroupTile extends StatelessWidget {
  final GroupModel group;
  final VoidCallback onTap;

  const GroupTile({
    super.key,
    required this.group,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;

    return ListTile(
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: modernTheme.surfaceVariantColor,
        backgroundImage:
            group.hasImage ? NetworkImage(group.groupImageUrl!) : null,
        child: group.hasImage
            ? null
            : Text(
                _getInitials(group.name),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: modernTheme.textColor,
                ),
              ),
      ),
      title: Text(
        group.displayName,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: modernTheme.textColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (group.hasLastMessage)
            Text(
              group.lastMessageText!,
              style: TextStyle(
                fontSize: 14,
                color: modernTheme.textSecondaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          else
            Text(
              group.displayDescription,
              style: TextStyle(
                fontSize: 14,
                color: modernTheme.textSecondaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.people,
                size: 12,
                color: modernTheme.textTertiaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                '${group.memberCount} ${group.memberCount == 1 ? 'member' : 'members'}',
                style: TextStyle(
                  fontSize: 12,
                  color: modernTheme.textTertiaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: group.lastMessageAt != null
          ? Text(
              group.lastMessageTimeAgo,
              style: TextStyle(
                fontSize: 12,
                color: modernTheme.textTertiaryColor,
              ),
            )
          : null,
      onTap: onTap,
    );
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }
    return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'
        .toUpperCase();
  }
}
