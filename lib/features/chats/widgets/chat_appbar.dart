import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:textgb/features/chats/providers/chat_activity_provider.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class ChatAppBar extends StatelessWidget {
  final UserModel contact;
  final ChatActivityState? activityState;
  final VoidCallback onProfileTap;
  
  const ChatAppBar({
    Key? key,
    required this.contact,
    this.activityState,
    required this.onProfileTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isOnline = activityState?.isOnline ?? false;
    final isTyping = activityState?.isTyping ?? false;
    final lastSeen = activityState?.lastSeen ?? '';
    
    return AppBar(
      backgroundColor: modernTheme.appBarColor,
      elevation: isDarkMode ? 0.0 : 1.0,
      leading: IconButton(
        icon: const Icon(CupertinoIcons.back),
        onPressed: () => Navigator.pop(context),
        color: modernTheme.textColor,
      ),
      titleSpacing: 0,
      title: InkWell(
        onTap: onProfileTap,
        child: Row(
          children: [
            // User avatar
            userImageWidget(
              imageUrl: contact.image,
              radius: 18,
              onTap: onProfileTap,
            ),
            const SizedBox(width: 12),
            
            // Name and status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Contact name
                  Text(
                    contact.name,
                    style: TextStyle(
                      color: modernTheme.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Status (online, typing, last seen)
                  if (isTyping)
                    Text(
                      'typing...',
                      style: TextStyle(
                        color: modernTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  else
                    Text(
                      isOnline ? 'Online' : _formatLastSeen(lastSeen),
                      style: TextStyle(
                        color: isOnline ? modernTheme.primaryColor : modernTheme.textSecondaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(CupertinoIcons.video_camera),
          onPressed: () {
            // Implement video call
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video call feature coming soon'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          color: modernTheme.primaryColor,
        ),
        IconButton(
          icon: const Icon(CupertinoIcons.phone),
          onPressed: () {
            // Implement voice call
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Voice call feature coming soon'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          color: modernTheme.primaryColor,
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            _showMoreOptions(context);
          },
          color: modernTheme.textColor,
        ),
      ],
    );
  }
  
  String _formatLastSeen(String lastSeen) {
    if (lastSeen.isEmpty) {
      return 'Last seen recently';
    }
    
    try {
      final lastSeenTimestamp = int.tryParse(lastSeen);
      if (lastSeenTimestamp == null) {
        return 'Last seen recently';
      }
      
      final lastSeenDateTime = DateTime.fromMillisecondsSinceEpoch(lastSeenTimestamp);
      final now = DateTime.now();
      final difference = now.difference(lastSeenDateTime);
      
      if (difference.inMinutes < 1) {
        return 'Last seen just now';
      } else if (difference.inHours < 1) {
        return 'Last seen ${difference.inMinutes} min ago';
      } else if (difference.inHours < 24) {
        return 'Last seen ${difference.inHours} h ago';
      } else {
        // Format date: Today, Yesterday, or date
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));
        final lastSeenDate = DateTime(lastSeenDateTime.year, lastSeenDateTime.month, lastSeenDateTime.day);
        
        if (lastSeenDate == today) {
          return 'Last seen today at ${lastSeenDateTime.hour}:${lastSeenDateTime.minute.toString().padLeft(2, '0')}';
        } else if (lastSeenDate == yesterday) {
          return 'Last seen yesterday at ${lastSeenDateTime.hour}:${lastSeenDateTime.minute.toString().padLeft(2, '0')}';
        } else {
          return 'Last seen ${lastSeenDateTime.day}/${lastSeenDateTime.month}/${lastSeenDateTime.year}';
        }
      }
    } catch (e) {
      return 'Last seen recently';
    }
  }
  
  void _showMoreOptions(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: modernTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.search, color: modernTheme.textColor),
                title: Text(
                  'Search',
                  style: TextStyle(color: modernTheme.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to search in conversation
                },
              ),
              ListTile(
                leading: Icon(Icons.notifications_off, color: modernTheme.textColor),
                title: Text(
                  'Mute notifications',
                  style: TextStyle(color: modernTheme.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Implement mute notifications
                },
              ),
              ListTile(
                leading: Icon(Icons.wallpaper, color: modernTheme.textColor),
                title: Text(
                  'Wallpaper',
                  style: TextStyle(color: modernTheme.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to wallpaper selection
                },
              ),
              ListTile(
                leading: Icon(Icons.block, color: Colors.red),
                title: const Text(
                  'Block contact',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showBlockConfirmation(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showBlockConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block ${contact.name}?'),
        content: Text(
          '${contact.name} will no longer be able to call you or send you messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement block contact
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${contact.name} has been blocked'),
                ),
              );
            },
            child: const Text('BLOCK'),
          ),
        ],
      ),
    );
  }
}