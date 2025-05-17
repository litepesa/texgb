// lib/features/chat/screens/chats_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
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
    
    // Watch chats stream
    final chatsStream = ref.watch(chatStreamProvider);
    
    return chatsStream.when(
      data: (chats) {
        if (chats.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8.0, bottom: 100),
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, WidgetRef ref, ChatModel chat) {
    final modernTheme = context.modernTheme;
    
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
    
    return Dismissible(
      key: Key('chat_${chat.id}'),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      secondaryBackground: Container(
        color: Colors.blue,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.archive,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Delete action
          return await _showDeleteConfirmation(context);
        } else {
          // Archive action
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Archive feature coming soon')),
          );
          return false;
        }
      },
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
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
            // No longer showing online indicator
          ],
        ),
        title: Text(
          chat.contactName,
          style: TextStyle(
            color: modernTheme.textColor,
            fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          _getLastMessagePreview(chat),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: chat.unreadCount > 0
                ? modernTheme.textColor
                : modernTheme.textSecondaryColor,
            fontWeight: chat.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              timeText,
              style: TextStyle(
                color: chat.unreadCount > 0
                    ? modernTheme.primaryColor
                    : modernTheme.textSecondaryColor,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 5),
            if (chat.unreadCount > 0)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: modernTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  chat.unreadCount.toString(),
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
        onLongPress: () => _showChatOptions(context, chat),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text('Are you sure you want to delete this chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showChatOptions(BuildContext context, ChatModel chat) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete chat'),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await _showDeleteConfirmation(context);
                if (confirm) {
                  // Implement chat deletion
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chat deleted')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_off),
              title: const Text('Mute notifications'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications muted')),
                );
              },
            ),
            if (!chat.isGroup)
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('View contact'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    Constants.contactProfileScreen,
                    arguments: {
                      'uid': chat.contactUID,
                    },
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Archive chat'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Archive feature coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
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
}