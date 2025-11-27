// lib/features/groups/widgets/member_tile.dart
import 'package:flutter/material.dart';
import 'package:textgb/features/groups/models/group_member_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class MemberTile extends StatelessWidget {
  final GroupMemberModel member;
  final bool isSelf;
  final bool isCurrentUserAdmin;
  final VoidCallback? onPromote;
  final VoidCallback? onDemote;
  final VoidCallback? onRemove;

  const MemberTile({
    super.key,
    required this.member,
    this.isSelf = false,
    this.isCurrentUserAdmin = false,
    this.onPromote,
    this.onDemote,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: modernTheme.surfaceVariantColor,
        backgroundImage:
            member.userImage != null ? NetworkImage(member.userImage!) : null,
        child: member.userImage == null
            ? Text(
                _getInitials(member.displayName),
                style: TextStyle(
                  fontSize: 16,
                  color: modernTheme.textColor,
                ),
              )
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              member.displayName,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: modernTheme.textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isSelf)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: modernTheme.infoColor?.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'You',
                style: TextStyle(
                  fontSize: 11,
                  color: modernTheme.infoColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (member.isAdmin)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: modernTheme.warningColor?.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        size: 12,
                        color: modernTheme.warningColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Admin',
                        style: TextStyle(
                          fontSize: 11,
                          color: modernTheme.warningColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                'Joined ${member.joinedTimeAgo}',
                style: TextStyle(
                  fontSize: 12,
                  color: modernTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
          if (member.userPhone != null)
            Text(
              member.userPhone!,
              style: TextStyle(
                fontSize: 12,
                color: modernTheme.textTertiaryColor,
              ),
            ),
        ],
      ),
      trailing: isCurrentUserAdmin && !isSelf
          ? PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: modernTheme.textColor),
              onSelected: (value) {
                switch (value) {
                  case 'promote':
                    onPromote?.call();
                    break;
                  case 'demote':
                    onDemote?.call();
                    break;
                  case 'remove':
                    onRemove?.call();
                    break;
                }
              },
              itemBuilder: (context) => [
                if (!member.isAdmin && onPromote != null)
                  PopupMenuItem(
                    value: 'promote',
                    child: Row(
                      children: [
                        Icon(Icons.arrow_upward, size: 18, color: modernTheme.textColor),
                        const SizedBox(width: 8),
                        Text('Promote to Admin', style: TextStyle(color: modernTheme.textColor)),
                      ],
                    ),
                  ),
                if (member.isAdmin && onDemote != null)
                  PopupMenuItem(
                    value: 'demote',
                    child: Row(
                      children: [
                        Icon(Icons.arrow_downward, size: 18, color: modernTheme.textColor),
                        const SizedBox(width: 8),
                        Text('Demote to Member', style: TextStyle(color: modernTheme.textColor)),
                      ],
                    ),
                  ),
                if (onRemove != null)
                  PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove, size: 18, color: modernTheme.errorColor),
                        const SizedBox(width: 8),
                        Text('Remove', style: TextStyle(color: modernTheme.errorColor)),
                      ],
                    ),
                  ),
              ],
            )
          : null,
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
