// lib/features/chat/screens/chats_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
import 'package:textgb/features/chat/repositories/chat_repository.dart';
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

        // Sort chats: pinned first, then by last message time
        directChats.sort((a, b) {
          // Check if either chat is pinned
          final aPinned = a.isPinned ?? false;
          final bPinned = b.isPinned ?? false;
          
          if (aPinned && !bPinned) return -1;
          if (!aPinned && bPinned) return 1;
          
          // If both have same pin status, sort by last message time
          final aTime = int.parse(a.lastMessageTime);
          final bTime = int.parse(b.lastMessageTime);
          return bTime.compareTo(aTime);
        });

        return RefreshIndicator(
          onRefresh: () async {
            ref.refresh(chatStreamProvider);
          },
          child: ListView.separated(
            padding: const EdgeInsets.only(top: 8.0, bottom: 100),
            itemCount: directChats.length,
            separatorBuilder: (context, index) => _buildDivider(context),
            itemBuilder: (context, index) {
              final chat = directChats[index];
              return _buildChatItem(context, ref, chat);
            },
          ),
        );
      },
      loading: () => _buildShimmerList(),
      error: (error, stack) => _buildErrorState(context, ref),
    );
  }

  Widget _buildShimmerList() {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8.0, bottom: 100),
      itemCount: 6,
      separatorBuilder: (context, index) => _buildDivider(context),
      itemBuilder: (context, index) => _buildShimmerItem(),
    );
  }

  Widget _buildShimmerItem() {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          shape: BoxShape.circle,
        ),
      ),
      title: Container(
        height: 16,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      subtitle: Container(
        height: 12,
        width: 200,
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      trailing: Container(
        height: 12,
        width: 50,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref) {
    final modernTheme = context.modernTheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: modernTheme.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load chats',
            style: TextStyle(
              fontSize: 18,
              color: modernTheme.textColor,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.refresh(chatStreamProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: modernTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Container(
      margin: const EdgeInsets.only(left: 72), // 16 (ListTile padding) + 40 (avatar) + 16 (gap) = 72
      height: 0.5,
      color: modernTheme.dividerColor?.withOpacity(0.3),
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
    final currentUser = ref.read(currentUserProvider);
    
    // Format time with better UX
    final timestamp = int.parse(chat.lastMessageTime);
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    String timeText;
    if (difference.inMinutes < 1) {
      timeText = 'now';
    } else if (difference.inMinutes < 60) {
      timeText = '${difference.inMinutes}m';
    } else if (difference.inHours < 24 && dateTime.day == now.day) {
      timeText = DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      timeText = 'Yesterday';
    } else if (difference.inDays < 7) {
      timeText = DateFormat('EEEE').format(dateTime);
    } else {
      timeText = DateFormat('dd/MM/yyyy').format(dateTime);
    }
    
    // Get the correct unread count for display - only counts received messages
    final unreadCount = chat.getDisplayUnreadCount();
    
    // Check if this is the sender of the last message
    final bool isLastMessageSender = currentUser != null && 
                                    chat.lastMessageSender == currentUser.uid;
                                    
    // Determine if there are unread messages
    final bool hasUnread = unreadCount > 0;
    final bool isPinned = chat.isPinned ?? false;
    
    return GestureDetector(
      onLongPress: () => _showChatOptions(context, ref, chat),
      child: ListTile(
        key: ValueKey(chat.id),
        leading: Stack(
          children: [
            _buildAvatar(chat, modernTheme),
            if (isPinned)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: modernTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.push_pin,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
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
                  Icons.done_all, // You can enhance this based on actual message status
                  size: 14,
                  color: modernTheme.textSecondaryColor,
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
        onTap: () => _openChatScreen(context, ref, chat),
      ),
    );
  }

  Widget _buildAvatar(ChatModel chat, ModernThemeExtension modernTheme) {
    if (chat.contactImage.isNotEmpty) {
      return CircleAvatar(
        backgroundColor: modernTheme.primaryColor!.withOpacity(0.2),
        child: CachedNetworkImage(
          imageUrl: chat.contactImage,
          imageBuilder: (context, imageProvider) => CircleAvatar(
            backgroundImage: imageProvider,
          ),
          placeholder: (context, url) => CircleAvatar(
            backgroundColor: modernTheme.primaryColor!.withOpacity(0.2),
            child: Text(
              _getAvatarInitials(chat.contactName),
              style: TextStyle(
                color: modernTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          errorWidget: (context, url, error) => CircleAvatar(
            backgroundColor: modernTheme.primaryColor!.withOpacity(0.2),
            child: Text(
              _getAvatarInitials(chat.contactName),
              style: TextStyle(
                color: modernTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }
    
    return CircleAvatar(
      backgroundColor: modernTheme.primaryColor!.withOpacity(0.2),
      child: Text(
        _getAvatarInitials(chat.contactName),
        style: TextStyle(
          color: modernTheme.primaryColor,
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

  void _showChatOptions(BuildContext context, WidgetRef ref, ChatModel chat) {
    final modernTheme = context.modernTheme;
    final isPinned = chat.isPinned ?? false;
    
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
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: modernTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(
                  isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                  color: modernTheme.textColor,
                ),
                title: Text(
                  isPinned ? 'Unpin chat' : 'Pin chat',
                  style: TextStyle(color: modernTheme.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _togglePinChat(context, ref, chat);
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
                  _confirmDeleteChat(context, ref, chat);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _togglePinChat(BuildContext context, WidgetRef ref, ChatModel chat) async {
    try {
      final chatRepository = ref.read(chatRepositoryProvider);
      await chatRepository.togglePinChat(chat.id);
      
      // Show feedback
      if (context.mounted) {
        final isPinned = !(chat.isPinned ?? false);
        showSnackBar(
          context, 
          isPinned ? 'Chat pinned' : 'Chat unpinned'
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Failed to ${(chat.isPinned ?? false) ? 'unpin' : 'pin'} chat');
      }
    }
  }

  void _confirmDeleteChat(BuildContext context, WidgetRef ref, ChatModel chat) {
    final modernTheme = context.modernTheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: modernTheme.surfaceColor,
        title: Text(
          'Delete Chat',
          style: TextStyle(color: modernTheme.textColor),
        ),
        content: Text(
          'Are you sure you want to delete this chat with ${chat.contactName}? This action cannot be undone.',
          style: TextStyle(color: modernTheme.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: modernTheme.textSecondaryColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteChat(context, ref, chat);
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

  void _deleteChat(BuildContext context, WidgetRef ref, ChatModel chat) async {
    try {
      final chatRepository = ref.read(chatRepositoryProvider);
      await chatRepository.deleteChat(chat.id);
      
      if (context.mounted) {
        showSnackBar(context, 'Chat deleted');
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Failed to delete chat');
      }
    }
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