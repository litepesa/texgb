// lib/features/chat/screens/chats_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

// Dummy chat data model
class DummyChatModel {
  final String id;
  final String contactName;
  final String contactUID;
  final String contactImage;
  final String lastMessage;
  final MessageEnum lastMessageType;
  final String lastMessageTime;
  final String lastMessageSender;
  final bool isPinned;
  final int unreadCount;
  final bool isGroup;

  DummyChatModel({
    required this.id,
    required this.contactName,
    required this.contactUID,
    required this.contactImage,
    required this.lastMessage,
    required this.lastMessageType,
    required this.lastMessageTime,
    required this.lastMessageSender,
    this.isPinned = false,
    this.unreadCount = 0,
    this.isGroup = false,
  });

  int getDisplayUnreadCount() => unreadCount;
}

class ChatsTab extends ConsumerStatefulWidget {
  const ChatsTab({Key? key}) : super(key: key);

  @override
  ConsumerState<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends ConsumerState<ChatsTab> {
  // Dummy data for demonstration
  final List<DummyChatModel> _dummyChats = [
    DummyChatModel(
      id: '1',
      contactName: 'John Smith',
      contactUID: '+254700123456',
      contactImage: '',
      lastMessage: 'Hey, how are you doing?',
      lastMessageType: MessageEnum.text,
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)).millisecondsSinceEpoch.toString(),
      lastMessageSender: '+254700123456',
      isPinned: true,
      unreadCount: 2,
    ),
    DummyChatModel(
      id: '2',
      contactName: 'Sarah Wilson',
      contactUID: '+254700654321',
      contactImage: '',
      lastMessage: 'Thanks for the help!',
      lastMessageType: MessageEnum.text,
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)).millisecondsSinceEpoch.toString(),
      lastMessageSender: 'current_user',
      unreadCount: 0,
    ),
    DummyChatModel(
      id: '3',
      contactName: 'Mike Johnson',
      contactUID: '+254700987654',
      contactImage: '',
      lastMessage: '',
      lastMessageType: MessageEnum.image,
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 4)).millisecondsSinceEpoch.toString(),
      lastMessageSender: '+254700987654',
      unreadCount: 1,
    ),
    DummyChatModel(
      id: '4',
      contactName: 'Emma Davis',
      contactUID: '+254700456789',
      contactImage: '',
      lastMessage: 'See you tomorrow!',
      lastMessageType: MessageEnum.text,
      lastMessageTime: DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch.toString(),
      lastMessageSender: '+254700456789',
      isPinned: false,
      unreadCount: 0,
    ),
    DummyChatModel(
      id: '5',
      contactName: 'Alex Brown',
      contactUID: '+254700789123',
      contactImage: '',
      lastMessage: '',
      lastMessageType: MessageEnum.audio,
      lastMessageTime: DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch.toString(),
      lastMessageSender: 'current_user',
      unreadCount: 3,
    ),
  ];

  bool _isLoading = false;
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Container(
      color: modernTheme.surfaceColor,
      child: _buildChatsContent(),
    );
  }

  Widget _buildChatsContent() {
    if (_isLoading) {
      return _buildShimmerList();
    }
    
    if (_hasError) {
      return _buildErrorState();
    }

    // Filter out group chats - only show direct chats
    final directChats = _dummyChats.where((chat) => !chat.isGroup).toList();
    
    if (directChats.isEmpty) {
      return _buildEmptyState();
    }

    // Sort chats: pinned first, then by last message time
    directChats.sort((a, b) {
      final aPinned = a.isPinned;
      final bPinned = b.isPinned;
      
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;
      
      final aTime = int.parse(a.lastMessageTime);
      final bTime = int.parse(b.lastMessageTime);
      return bTime.compareTo(aTime);
    });

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _isLoading = true;
        });
        // Simulate network delay
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          _isLoading = false;
        });
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8.0, bottom: 100),
        itemCount: directChats.length,
        itemBuilder: (context, index) {
          final chat = directChats[index];
          return _buildChatItem(chat);
        },
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8.0, bottom: 100),
      itemCount: 6,
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

  Widget _buildErrorState() {
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
            onPressed: () {
              setState(() {
                _hasError = false;
                _isLoading = true;
              });
              Future.delayed(const Duration(seconds: 1), () {
                setState(() {
                  _isLoading = false;
                });
              });
            },
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

  Widget _buildEmptyState() {
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

  Widget _buildChatItem(DummyChatModel chat) {
    final modernTheme = context.modernTheme;
    
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
    
    final unreadCount = chat.getDisplayUnreadCount();
    final bool isLastMessageSender = chat.lastMessageSender == 'current_user';
    final bool hasUnread = unreadCount > 0;
    final bool isPinned = chat.isPinned;
    
    return GestureDetector(
      onLongPress: () => _showChatOptions(chat),
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
            if (isLastMessageSender)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.done_all,
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
        onTap: () => _openChatScreen(chat),
      ),
    );
  }

  Widget _buildAvatar(DummyChatModel chat, ModernThemeExtension modernTheme) {
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

  void _showChatOptions(DummyChatModel chat) {
    final modernTheme = context.modernTheme;
    final isPinned = chat.isPinned;
    
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
                  _togglePinChat(chat);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
                title: const Text(
                  'Delete chat',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteChat(chat);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _togglePinChat(DummyChatModel chat) async {
    // Simulate async operation
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Update dummy data
    final index = _dummyChats.indexWhere((c) => c.id == chat.id);
    if (index != -1) {
      // In real implementation, you would update the actual data
      // For now, just show feedback
      final wasPinned = chat.isPinned;
      if (context.mounted) {
        showSnackBar(
          context, 
          wasPinned ? 'Chat unpinned' : 'Chat pinned'
        );
        setState(() {}); // Refresh the UI
      }
    }
  }

  void _confirmDeleteChat(DummyChatModel chat) {
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
              _deleteChat(chat);
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

  void _deleteChat(DummyChatModel chat) async {
    // Simulate async operation
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Remove from dummy data
    _dummyChats.removeWhere((c) => c.id == chat.id);
    
    if (context.mounted) {
      showSnackBar(context, 'Chat deleted');
      setState(() {}); // Refresh the UI
    }
  }

  String _getLastMessagePreview(DummyChatModel chat) {
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

  void _openChatScreen(DummyChatModel chat) async {
    // Simulate opening chat screen with dummy data
    showSnackBar(context, 'Opening chat with ${chat.contactName}...');
    
    // In real implementation, this would navigate to the actual chat screen
    // For now, just simulate the navigation
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (context.mounted) {
      // This would normally navigate to the chat screen
      // Navigator.pushNamed(
      //   context,
      //   Constants.chatScreen,
      //   arguments: {
      //     'chatId': chat.id,
      //     'contact': dummyContact,
      //   },
      // );
    }
  }
}