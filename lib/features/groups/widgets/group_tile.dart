// lib/features/groups/widgets/group_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/groups/models/group_model.dart';
import 'package:textgb/features/groups/providers/group_provider.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    
    return ListTile(
      key: ValueKey(widget.group.groupId),
      leading: _buildAvatar(theme),
      title: Text(
        widget.group.groupName,
        style: TextStyle(
          color: theme.textColor,
          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        widget.group.lastMessage.isNotEmpty
            ? widget.group.getLastMessagePreview()
            : widget.group.groupDescription.isNotEmpty
                ? widget.group.groupDescription
                : 'Group created',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: hasUnread
              ? theme.textColor
              : theme.textSecondaryColor,
          fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(widget.group.lastMessageTime.isNotEmpty
                ? widget.group.lastMessageTime
                : widget.group.createdAt),
            style: TextStyle(
              color: hasUnread
                  ? theme.primaryColor
                  : theme.textSecondaryColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          if (hasUnread)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: widget.onTap,
    );
  }

  Widget _buildAvatar(ModernThemeExtension theme) {
    if (widget.group.groupImage.isNotEmpty) {
      return CircleAvatar(
        backgroundColor: theme.primaryColor!.withOpacity(0.2),
        child: CachedNetworkImage(
          imageUrl: widget.group.groupImage,
          imageBuilder: (context, imageProvider) => CircleAvatar(
            backgroundImage: imageProvider,
          ),
          placeholder: (context, url) => CircleAvatar(
            backgroundColor: theme.primaryColor!.withOpacity(0.2),
            child: Text(
              _getAvatarInitials(widget.group.groupName),
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          errorWidget: (context, url, error) => CircleAvatar(
            backgroundColor: theme.primaryColor!.withOpacity(0.2),
            child: Text(
              _getAvatarInitials(widget.group.groupName),
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }
    
    return CircleAvatar(
      backgroundColor: theme.primaryColor!.withOpacity(0.2),
      child: Text(
        _getAvatarInitials(widget.group.groupName),
        style: TextStyle(
          color: theme.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getAvatarInitials(String name) {
    if (name.isEmpty) return '?';
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _formatTime(String timeString) {
    if (timeString.isEmpty) return '';
    
    final timestamp = int.tryParse(timeString);
    if (timestamp == null) return '';
    
    final messageTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(messageTime);
    
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24 && messageTime.day == now.day) {
      final hour = messageTime.hour == 0 ? 12 : (messageTime.hour > 12 ? messageTime.hour - 12 : messageTime.hour);
      final minute = messageTime.minute.toString().padLeft(2, '0');
      final period = messageTime.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[messageTime.weekday - 1];
    } else {
      return '${messageTime.day}/${messageTime.month}/${messageTime.year}';
    }
  }
}