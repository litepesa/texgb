import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/chats/models/chat_model.dart';
import 'package:textgb/features/contacts/providers/contacts_provider.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class ChatListItem extends ConsumerWidget {
  final ChatModel chat;
  final Function(UserModel) onTap;
  final Function(UserModel) onLongPress;

  const ChatListItem({
    Key? key,
    required this.chat,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modernTheme = context.modernTheme;
    final contacts = ref.watch(contactsStreamProvider);
    
    return contacts.when(
      data: (contactsList) {
        // Find the contact for this chat
        final contact = contactsList.firstWhere(
          (c) => c.uid == chat.contactUID,
          orElse: () => UserModel(
            uid: chat.contactUID,
            name: 'Unknown Contact',
            phoneNumber: '',
            image: '',
            token: '',
            aboutMe: '',
            lastSeen: '',
            createdAt: '',
            isOnline: false,
            contactsUIDs: [],
            blockedUIDs: [],
          ),
        );
        
        return _buildListItem(context, contact);
      },
      error: (error, stackTrace) => ListTile(
        title: Text('Error loading contact'),
        subtitle: Text(error.toString()),
      ),
      loading: () => const ListTile(
        leading: CircleAvatar(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text('Loading...'),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, UserModel contact) {
    final modernTheme = context.modernTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Format timestamp
    final timestamp = DateTime.fromMillisecondsSinceEpoch(chat.timeSent);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDay = DateTime(timestamp.year, timestamp.month, timestamp.day);
    
    String timeString;
    if (messageDay == today) {
      timeString = DateFormat('HH:mm').format(timestamp);
    } else if (messageDay == yesterday) {
      timeString = 'Yesterday';
    } else if (timestamp.year == now.year) {
      timeString = DateFormat('dd/MM').format(timestamp);
    } else {
      timeString = DateFormat('dd/MM/yy').format(timestamp);
    }

    return InkWell(
      onTap: () => onTap(contact),
      onLongPress: () => onLongPress(contact),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: chat.isPinned
              ? modernTheme.surfaceVariantColor
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: modernTheme.dividerColor ?? Colors.grey.withOpacity(0.2),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // User avatar with online indicator
            Stack(
              children: [
                userImageWidget(
                  imageUrl: contact.image,
                  radius: 24,
                  onTap: () => onTap(contact),
                ),
                if (contact.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: modernTheme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: modernTheme.backgroundColor ?? Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(width: 16),
            
            // Chat info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name row with timestamp
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          contact.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: chat.unreadCount > 0
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: modernTheme.textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeString,
                        style: TextStyle(
                          fontSize: 12,
                          color: chat.unreadCount > 0
                              ? modernTheme.primaryColor
                              : modernTheme.textSecondaryColor,
                          fontWeight: chat.unreadCount > 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Last message with unread count
                  Row(
                    children: [
                      // Sender indicator for group chats (future implementation)
                      // if (isGroup) ...
                      
                      // Last message content/preview
                      Expanded(
                        child: Row(
                          children: [
                            if (chat.lastMessageType != MessageEnum.text)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Icon(
                                  chat.lastMessageType.icon,
                                  size: 16,
                                  color: modernTheme.textSecondaryColor,
                                ),
                              ),
                            Flexible(
                              child: Text(
                                _getLastMessageText(chat),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: chat.unreadCount > 0
                                      ? modernTheme.textColor
                                      : modernTheme.textSecondaryColor,
                                  fontWeight: chat.unreadCount > 0
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Muted/unread indicators
                      Row(
                        children: [
                          if (chat.isMuted)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.volume_off,
                                size: 16,
                                color: modernTheme.textSecondaryColor,
                              ),
                            ),
                          if (chat.unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: modernTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Center(
                                child: Text(
                                  chat.unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLastMessageText(ChatModel chat) {
    switch (chat.lastMessageType) {
      case MessageEnum.text:
        return chat.lastMessage;
      case MessageEnum.image:
        return 'Photo';
      case MessageEnum.video:
        return 'Video';
      case MessageEnum.audio:
        return 'Voice message';
      case MessageEnum.file:
        return 'Document';
      case MessageEnum.location:
        return 'Location';
      case MessageEnum.contact:
        return 'Contact';
    }
  }}