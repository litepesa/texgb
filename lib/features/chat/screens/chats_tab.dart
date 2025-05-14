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
            return _buildChatItem(context, chat);
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

  Widget _buildChatItem(BuildContext context, ChatModel chat) {
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
    
    return ListTile(
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
      onTap: () => _openChatScreen(context, chat),
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

  void _openChatScreen(BuildContext context, ChatModel chat) async {
    try {
      // Get contact user data
      final contactsProvider = ProviderContainer().read(contactsNotifierProvider.notifier);
      final contact = await contactsProvider.searchUserByPhoneNumber(chat.contactUID);
      
      if (contact != null) {
        Navigator.pushNamed(
          context,
          Constants.chatScreen,
          arguments: {
            'chatId': chat.id,
            'contact': contact,
          },
        );
      } else {
        showSnackBar(context, 'Contact not found');
      }
    } catch (e) {
      showSnackBar(context, 'Error opening chat: $e');
    }
  }
}