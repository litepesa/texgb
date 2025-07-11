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
        final isLocalAdmin = widget.group.isAdmin(currentUser.uid);
        
        if (isLocalAdmin != _isAdmin) {
          setState(() {
            _isAdmin = isLocalAdmin;
          });
        }

        final isActualAdmin = await ref.read(groupProvider.notifier)
            .isCurrentUserAdmin(widget.group.groupId);
        
        if (isActualAdmin != _isAdmin && mounted) {
          setState(() {
            _isAdmin = isActualAdmin;
          });
        }
      }
    } catch (e) {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null && mounted) {
        final localAdmin = widget.group.isAdmin(currentUser.uid);
        if (localAdmin != _isAdmin) {
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
    
    final unreadCount = currentUser != null 
        ? widget.group.getUnreadCountForUser(currentUser.uid)
        : 0;
    final hasUnread = unreadCount > 0;
    
    return Container(
      color: theme.surfaceColor, // Use surfaceColor background
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: theme.primaryColor!.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: widget.group.groupImage.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    widget.group.groupImage,
                    fit: BoxFit.cover,
                    width: 56,
                    height: 56,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildFallbackAvatar(theme);
                    },
                  ),
                )
              : _buildFallbackAvatar(theme),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.group.groupName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
                  color: theme.textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_isAdmin && !_isCheckingAdmin) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.primaryColor!.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Admin',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            Text(
              _formatTime(widget.group.lastMessageTime.isNotEmpty
                  ? widget.group.lastMessageTime
                  : widget.group.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: hasUnread 
                    ? theme.primaryColor 
                    : theme.textSecondaryColor,
                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.group.lastMessage.isNotEmpty
                        ? widget.group.getLastMessagePreview()
                        : widget.group.groupDescription.isNotEmpty
                            ? widget.group.groupDescription
                            : 'Group created',
                    style: TextStyle(
                      fontSize: 14,
                      color: hasUnread 
                          ? theme.textColor!.withOpacity(0.8)
                          : theme.textSecondaryColor,
                      fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasUnread) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: unreadCount > 99 ? 6 : 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      shape: unreadCount > 99 ? BoxShape.rectangle : BoxShape.circle,
                      borderRadius: unreadCount > 99 ? BorderRadius.circular(10) : null,
                    ),
                    constraints: BoxConstraints(
                      minWidth: unreadCount > 99 ? 24 : 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.people_alt_rounded,
                  size: 14,
                  color: theme.textSecondaryColor!.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.group.membersUIDs.length} members',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textSecondaryColor!.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: widget.onTap,
      ),
    );
  }

  Widget _buildFallbackAvatar(ModernThemeExtension theme) {
    return Center(
      child: Icon(
        Icons.group_rounded,
        size: 28,
        color: theme.primaryColor,
      ),
    );
  }

  String _formatTime(String timeString) {
    if (timeString.isEmpty) return '';
    
    final timestamp = int.tryParse(timeString);
    if (timestamp == null) return '';
    
    final messageTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(messageTime.year, messageTime.month, messageTime.day);
    
    if (messageDate == today) {
      // Today - show time
      final hour = messageTime.hour == 0 ? 12 : (messageTime.hour > 12 ? messageTime.hour - 12 : messageTime.hour);
      final minute = messageTime.minute.toString().padLeft(2, '0');
      final period = messageTime.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return 'Yesterday';
    } else if (now.difference(messageTime).inDays < 7) {
      // This week - show day name
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[messageTime.weekday - 1];
    } else {
      // Older - show date
      return '${messageTime.day}/${messageTime.month}/${messageTime.year}';
    }
  }
}