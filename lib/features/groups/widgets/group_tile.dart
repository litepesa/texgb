// lib/features/groups/widgets/group_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/groups/models/group_model.dart';
import 'package:textgb/features/groups/providers/group_provider.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class GroupTile extends ConsumerStatefulWidget {
  final GroupModel group;
  final VoidCallback? onTap;

  const GroupTile({
    super.key,
    required this.group,
    this.onTap,
  });

  @override
  ConsumerState<GroupTile> createState() => _GroupTileState();
}

class _GroupTileState extends ConsumerState<GroupTile> {
  bool _isAdmin = false;
  bool _isCheckingAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  @override
  void didUpdateWidget(GroupTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-check admin status if group changed
    if (oldWidget.group.groupId != widget.group.groupId) {
      _checkAdminStatus();
    }
  }

  Future<void> _checkAdminStatus() async {
    if (_isCheckingAdmin) return;
    
    setState(() {
      _isCheckingAdmin = true;
    });

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        // First check local group data for quick response
        final isLocalAdmin = widget.group.isAdmin(currentUser.uid);
        
        if (isLocalAdmin != _isAdmin) {
          setState(() {
            _isAdmin = isLocalAdmin;
          });
        }

        // Then verify with security service for accuracy
        final isActualAdmin = await ref.read(groupProvider.notifier)
            .isCurrentUserAdmin(widget.group.groupId);
        
        if (isActualAdmin != _isAdmin && mounted) {
          setState(() {
            _isAdmin = isActualAdmin;
          });
        }
      }
    } catch (e) {
      // If there's an error, fall back to local group data
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        final localAdmin = widget.group.isAdmin(currentUser.uid);
        if (localAdmin != _isAdmin && mounted) {
          setState(() {
            _isAdmin = localAdmin;
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingAdmin = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    final currentUser = ref.watch(currentUserProvider);
    
    // Calculate unread messages for this group
    final unreadCount = currentUser != null 
        ? widget.group.getUnreadCountForUser(currentUser.uid)
        : 0;
    final hasUnread = unreadCount > 0;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: hasUnread ? theme.surfaceVariantColor?.withOpacity(0.3) : theme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.borderColor!.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Group image
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.primaryColor!.withOpacity(0.2),
                backgroundImage: widget.group.groupImage.isNotEmpty
                    ? NetworkImage(widget.group.groupImage)
                    : null,
                child: widget.group.groupImage.isEmpty
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
                            widget.group.groupName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                              color: theme.textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Admin badge with loading state
                        if (_isCheckingAdmin)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.primaryColor,
                            ),
                          )
                        else if (_isAdmin)
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
                      widget.group.lastMessage.isNotEmpty
                          ? widget.group.getLastMessagePreview()
                          : widget.group.groupDescription,
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
                          color: theme.textTertiaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.group.membersUIDs.length} members',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTertiaryColor,
                          ),
                        ),
                        const Spacer(),
                        // Last message time or creation date
                        Text(
                          _formatTime(widget.group.lastMessageTime.isNotEmpty
                              ? widget.group.lastMessageTime
                              : widget.group.createdAt),
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