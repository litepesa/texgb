// lib/features/chat/screens/chats_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
import 'package:textgb/features/contacts/providers/contacts_provider.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class ChatsTab extends ConsumerWidget {
  const ChatsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modernTheme = context.modernTheme;
    final currentUser = ref.watch(currentUserProvider);
    
    // Watch chats stream
    final chatsStream = ref.watch(chatStreamProvider);
    
    return chatsStream.when(
      data: (chats) {
        // Filter out group chats - only show direct chats
        final directChats = chats.where((chat) => !chat.isGroup).toList();
        
        if (directChats.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8.0, bottom: 100),
          itemCount: directChats.length,
          itemBuilder: (context, index) {
            final chat = directChats[index];
            return _buildChatItem(context, ref, chat);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Text('Error loading chats: $error'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: modernTheme.textSecondaryColor?.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No chats yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: modernTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a new chat with your contacts',
            style: TextStyle(
              fontSize: 16,
              color: modernTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, Constants.contactsScreen);
            },
            icon: const Icon(Icons.person_add),
            label: const Text('New Chat'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              backgroundColor: modernTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, WidgetRef ref, ChatModel chat) {
    final modernTheme = context.modernTheme;
    final chatTheme = context.chatTheme;
    final animationTheme = context.animationTheme;
    final currentUser = ref.read(currentUserProvider);
    
    // Format time
    final timestamp = int.parse(chat.lastMessageTime);
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    
    String timeText;
    if (dateTime.year == now.year && 
        dateTime.month == now.month && 
        dateTime.day == now.day) {
      // Today - show time
      timeText = DateFormat('HH:mm').format(dateTime);
    } else if (dateTime.year == yesterday.year && 
               dateTime.month == yesterday.month && 
               dateTime.day == yesterday.day) {
      // Yesterday
      timeText = 'Yesterday';
    } else if (now.difference(dateTime).inDays < 7) {
      // Within the last week - show day name
      timeText = DateFormat('EEEE').format(dateTime);
    } else {
      // Older - show date
      timeText = DateFormat('dd/MM/yyyy').format(dateTime);
    }
    
    // Get the correct unread count for display - only counts received messages
    final unreadCount = chat.getDisplayUnreadCount();
    
    // Check if this is the sender of the last message
    final bool isLastMessageSender = currentUser != null && 
                                    chat.lastMessageSender == currentUser.uid;
                                    
    // Determine if there are unread messages
    final bool hasUnread = unreadCount > 0;
    
    return AnimatedContainer(
      duration: animationTheme.shortDuration,
      curve: animationTheme.standardCurve,
      decoration: BoxDecoration(
        color: hasUnread ? modernTheme.surfaceVariantColor?.withOpacity(0.3) : Colors.transparent,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: modernTheme.primaryColor!.withOpacity(0.2),
          backgroundImage: chat.contactImage.isNotEmpty
              ? NetworkImage(chat.contactImage)
              : null,
          child: chat.contactImage.isEmpty
              ? Text(
                  chat.contactName.isNotEmpty
                      ? chat.contactName.substring(0, 1)
                      : '?',
                  style: TextStyle(
                    color: modernTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          chat.contactName,
          style: TextStyle(
            color: modernTheme.textColor,
            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Row(
          children: [
            // Message status indicator (only for messages sent by current user)
            if (isLastMessageSender)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  _getMessageStatusIcon(),
                  size: 14,
                  color: _getMessageStatusColor(context),
                ),
              ),
            Expanded(
              child: Text(
                _getLastMessagePreview(chat),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: hasUnread
                      ? modernTheme.textColor
                      : modernTheme.textSecondaryColor,
                  fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              timeText,
              style: TextStyle(
                color: hasUnread
                    ? modernTheme.primaryColor
                    : modernTheme.textSecondaryColor,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 5),
            if (hasUnread)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: modernTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap: () => _openChatScreen(context, ref, chat),
        onLongPress: () => _showChatOptions(context, ref, chat),
      ),
    );
  }
  
  // Helper method to get the appropriate message status icon
  IconData _getMessageStatusIcon() {
    // We don't have access to the actual message status from the chat list
    // So we'll just use a simple sent icon
    return Icons.done;
  }
  
  // Helper method to get the appropriate message status color
  Color _getMessageStatusColor(BuildContext context) {
    return context.modernTheme.textSecondaryColor ?? Colors.grey;
  }

  String _getLastMessagePreview(ChatModel chat) {
    switch (chat.lastMessageType) {
      case MessageEnum.text:
        return chat.lastMessage;
      case MessageEnum.image:
        return '📷 Photo';
      case MessageEnum.video:
        return '🎥 Video';
      case MessageEnum.audio:
        return '🎵 Audio message';
      case MessageEnum.file:
        return '📎 Document';
      case MessageEnum.location:
        return '📍 Location';
      case MessageEnum.contact:
        return '👤 Contact';
      default:
        return chat.lastMessage;
    }
  }

  void _openChatScreen(BuildContext context, WidgetRef ref, ChatModel chat) async {
    try {
      // Get contact data
      final contactsNotifier = ref.read(contactsNotifierProvider.notifier);
      final contact = await contactsNotifier.searchUserByPhoneNumber(chat.contactUID);
      
      if (contact != null) {
        // First open the chat directly with the ChatNotifier
        await ref.read(chatProvider.notifier).openChat(chat.id, contact);

        // Then navigate to the chat screen
        if (context.mounted) {
          Navigator.pushNamed(
            context,
            Constants.chatScreen,
            arguments: {
              'chatId': chat.id,
              'contact': contact,
            },
          );
        }
      } else {
        // Use the contact information from the chat model as fallback
        // This ensures we can still open the chat even if we can't fetch the full contact
        final fallbackContact = UserModel(
          uid: chat.contactUID,
          name: chat.contactName,
          phoneNumber: chat.contactUID, // Using contactUID as phoneNumber
          image: chat.contactImage,
          aboutMe: '',
          lastSeen: DateTime.now().millisecondsSinceEpoch.toString(),
          token: '',
          createdAt: DateTime.now().millisecondsSinceEpoch.toString(),
          contactsUIDs: [],
          blockedUIDs: [],
        );
        
        await ref.read(chatProvider.notifier).openChat(chat.id, fallbackContact);

        if (context.mounted) {
          Navigator.pushNamed(
            context,
            Constants.chatScreen,
            arguments: {
              'chatId': chat.id,
              'contact': fallbackContact,
            },
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Error opening chat: $e');
      }
    }
  }
  
  void _showChatOptions(BuildContext context, WidgetRef ref, ChatModel chat) {
    final modernTheme = context.modernTheme;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: modernTheme.primaryColor!.withOpacity(0.2),
                  backgroundImage: chat.contactImage.isNotEmpty
                      ? NetworkImage(chat.contactImage)
                      : null,
                  child: chat.contactImage.isEmpty
                      ? Text(
                          chat.contactName.isNotEmpty
                              ? chat.contactName.substring(0, 1)
                              : '?',
                          style: TextStyle(
                            color: modernTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                title: Text(
                  chat.contactName,
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  Icons.block,
                  color: modernTheme.textSecondaryColor,
                ),
                title: const Text('Block contact'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement block contact functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Block contact feature coming soon')),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.volume_off,
                  color: modernTheme.textSecondaryColor,
                ),
                title: const Text('Mute notifications'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement mute notifications functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mute notifications feature coming soon')),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
                title: const Text(
                  'Delete chat',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteChatConfirmation(context, ref, chat);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteChatConfirmation(BuildContext context, WidgetRef ref, ChatModel chat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat?'),
        content: Text(
          'Are you sure you want to delete your conversation with ${chat.contactName}? This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Deleting chat...'))
              );
              
              try {
                // Delete the chat
                await ref.read(chatProvider.notifier).deleteChat(chat.id);
                
                if (context.mounted) {
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chat deleted successfully'))
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting chat: $e'))
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}