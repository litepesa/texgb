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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasUnread 
                  ? theme.primaryColor!.withOpacity(0.05)
                  : theme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasUnread
                    ? theme.primaryColor!.withOpacity(0.2)
                    : theme.borderColor!.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Group avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: theme.primaryColor!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: widget.group.groupImage.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            widget.group.groupImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildFallbackAvatar(theme);
                            },
                          ),
                        )
                      : _buildFallbackAvatar(theme),
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
                                fontSize: 17,
                                fontWeight: hasUnread 
                                    ? FontWeight.w700 
                                    : FontWeight.w600,
                                color: theme.textColor,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_isCheckingAdmin)
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.primaryColor,
                              ),
                            )
                          else if (_isAdmin)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.primaryColor!.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.primaryColor!.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Admin',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.group.lastMessage.isNotEmpty
                            ? widget.group.getLastMessagePreview()
                            : widget.group.groupDescription,
                        style: TextStyle(
                          fontSize: 14,
                          color: hasUnread 
                              ? theme.textColor 
                              : theme.textSecondaryColor,
                          fontWeight: hasUnread 
                              ? FontWeight.w500 
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.people_alt_rounded,
                            size: 16,
                            color: theme.textTertiaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.group.membersUIDs.length} members',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.textTertiaryColor,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatTime(widget.group.lastMessageTime.isNotEmpty
                                ? widget.group.lastMessageTime
                                : widget.group.createdAt),
                            style: TextStyle(
                              fontSize: 13,
                              color: hasUnread 
                                  ? theme.primaryColor 
                                  : theme.textTertiaryColor,
                              fontWeight: hasUnread 
                                  ? FontWeight.w600 
                                  : FontWeight.normal,
                            ),
                          ),
                          if (hasUnread) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: unreadCount > 99 ? 8 : 6,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              constraints: BoxConstraints(
                                minWidth: unreadCount > 99 ? 28 : 20,
                                minHeight: 20,
                              ),
                              child: Center(
                                child: Text(
                                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
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
    final difference = now.difference(messageTime);
    
    if (difference.inDays > 7) {
      return '${messageTime.day}/${messageTime.month}/${messageTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}