import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/chats/models/chat_model.dart';
import 'package:textgb/features/chats/providers/chat_provider.dart';
import 'package:textgb/features/chats/screens/chat_conversation_screen.dart';
import 'package:textgb/features/contacts/screens/contacts_screen.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/contacts/providers/contacts_provider.dart';
import 'package:textgb/features/chats/widgets/chat_list_item.dart';
import 'package:textgb/widgets/error_widget.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final modernTheme = context.modernTheme;
    final chatProvider = ref.watch(chatNotifierProvider);
    final authProvider = ref.watch(authenticationProvider);

    return Scaffold(
      appBar: _buildAppBar(modernTheme),
      body: chatProvider.when(
        data: (chats) => _buildChatsList(chats, modernTheme),
        error: (error, stackTrace) => CustomErrorWidget(
          error: error.toString(),
          onRetry: () => ref.refresh(chatNotifierProvider),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ContactsScreen(),
            ),
          );
        },
        backgroundColor: modernTheme.primaryColor,
        elevation: 4.0,
        child: const Icon(CupertinoIcons.chat_bubble_text, size: 26),
      ),
    );
  }

  AppBar _buildAppBar(ModernThemeExtension modernTheme) {
    return AppBar(
      elevation: 1.0,
      backgroundColor: modernTheme.appBarColor,
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search chats...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: modernTheme.textSecondaryColor),
              ),
              style: TextStyle(color: modernTheme.textColor),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            )
          : Text(
              'Chats',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: modernTheme.textColor,
              ),
            ),
      actions: [
        if (_isSearching)
          IconButton(
            icon: Icon(Icons.close, color: modernTheme.textColor),
            onPressed: _stopSearch,
          )
        else
          IconButton(
            icon: Icon(Icons.search, color: modernTheme.textColor),
            onPressed: _startSearch,
          ),
        IconButton(
          icon: Icon(Icons.more_vert, color: modernTheme.textColor),
          onPressed: () {
            _showOptionsMenu(context);
          },
        ),
      ],
    );
  }

  Widget _buildChatsList(List<ChatModel> chats, ModernThemeExtension modernTheme) {
    if (chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.chat_bubble_text,
              size: 70,
              color: modernTheme.textSecondaryColor?.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No chats yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: modernTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation with your contacts',
              style: TextStyle(
                fontSize: 14,
                color: modernTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ContactsScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Start a Chat'),
            ),
          ],
        ),
      );
    }

    // Sort chats: pinned first, then by most recent
    final pinnedChats = chats.where((chat) => chat.isPinned).toList();
    final unpinnedChats = chats.where((chat) => !chat.isPinned).toList();
    
    // Sort by time
    pinnedChats.sort((a, b) => b.timeSent.compareTo(a.timeSent));
    unpinnedChats.sort((a, b) => b.timeSent.compareTo(a.timeSent));
    
    final allChats = [...pinnedChats, ...unpinnedChats];
    
    // Filter by search query if searching
    List<ChatModel> filteredChats = allChats;
    if (_searchQuery.isNotEmpty) {
      filteredChats = allChats.where((chat) {
        // We need to get contact names from contacts provider
        return _matchesChatSearch(chat, _searchQuery.toLowerCase());
      }).toList();
    }

    if (filteredChats.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Text(
          'No chats found for "$_searchQuery"',
          style: TextStyle(color: modernTheme.textSecondaryColor),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: filteredChats.length,
      itemBuilder: (context, index) {
        final chat = filteredChats[index];
        return _buildChatItem(chat);
      },
    );
  }

  bool _matchesChatSearch(ChatModel chat, String query) {
    // Get the contact name from the contact provider
    final contactsProvider = ref.read(contactsStreamProvider);
    if (contactsProvider.asData == null) return false;
    
    final contacts = contactsProvider.asData!.value;
    final contact = contacts.firstWhere(
      (c) => c.uid == chat.contactUID,
      orElse: () => UserModel(
        uid: '',
        name: 'Unknown',
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
    
    return contact.name.toLowerCase().contains(query) || 
           chat.lastMessage.toLowerCase().contains(query);
  }

  Widget _buildChatItem(ChatModel chat) {
    return ChatListItem(
      chat: chat,
      onTap: (contactUser) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatConversationScreen(contact: contactUser),
          ),
        );
      },
      onLongPress: (contactUser) {
        _showChatOptions(chat, contactUser);
      },
    );
  }

  void _showChatOptions(ChatModel chat, UserModel contact) {
    final chatNotifier = ref.read(chatNotifierProvider.notifier);
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
                leading: const Icon(Icons.push_pin),
                title: Text(
                  chat.isPinned ? 'Unpin chat' : 'Pin chat',
                  style: TextStyle(color: modernTheme.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handlePinChat(chat, contact);
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_off),
                title: Text(
                  chat.isMuted ? 'Unmute notifications' : 'Mute notifications',
                  style: TextStyle(color: modernTheme.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleMuteChat(chat, contact);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(
                  'Delete chat',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteChat(chat, contact);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handlePinChat(ChatModel chat, UserModel contact) {
    final authState = ref.read(authenticationProvider);
    final currentUID = authState.value?.uid;
    
    if (currentUID == null) return;
    
    final chatNotifier = ref.read(chatNotifierProvider.notifier);
    
    // Create a consistent chat ID
    final sortedUIDs = [currentUID, contact.uid]..sort();
    final chatId = '${sortedUIDs[0]}-${sortedUIDs[1]}';
    
    chatNotifier.togglePinChat(
      uid: currentUID,
      chatId: chatId,
      isPinned: !chat.isPinned,
    );
  }

  void _handleMuteChat(ChatModel chat, UserModel contact) {
    final authState = ref.read(authenticationProvider);
    final currentUID = authState.value?.uid;
    
    if (currentUID == null) return;
    
    final chatNotifier = ref.read(chatNotifierProvider.notifier);
    
    // Create a consistent chat ID
    final sortedUIDs = [currentUID, contact.uid]..sort();
    final chatId = '${sortedUIDs[0]}-${sortedUIDs[1]}';
    
    chatNotifier.toggleMuteChat(
      uid: currentUID,
      chatId: chatId,
      isMuted: !chat.isMuted,
    );
  }

  void _confirmDeleteChat(ChatModel chat, UserModel contact) {
    final modernTheme = context.modernTheme;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: modernTheme.surfaceColor,
          title: Text(
            'Delete Chat',
            style: TextStyle(color: modernTheme.textColor),
          ),
          content: Text(
            'Are you sure you want to delete this chat? This action cannot be undone.',
            style: TextStyle(color: modernTheme.textSecondaryColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: modernTheme.textColor),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteChat(chat, contact);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteChat(ChatModel chat, UserModel contact) {
    final authState = ref.read(authenticationProvider);
    final currentUID = authState.value?.uid;
    
    if (currentUID == null) return;
    
    final chatNotifier = ref.read(chatNotifierProvider.notifier);
    
    // Create a consistent chat ID
    final sortedUIDs = [currentUID, contact.uid]..sort();
    final chatId = '${sortedUIDs[0]}-${sortedUIDs[1]}';
    
    chatNotifier.deleteChat(
      uid: currentUID,
      chatId: chatId,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chat deleted'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
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
                leading: Icon(Icons.mark_chat_read, color: modernTheme.textColor),
                title: Text(
                  'Mark all as read',
                  style: TextStyle(color: modernTheme.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Implementation for mark all as read
                },
              ),
              ListTile(
                leading: Icon(Icons.star, color: modernTheme.textColor),
                title: Text(
                  'Starred messages',
                  style: TextStyle(color: modernTheme.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to starred messages
                },
              ),
              ListTile(
                leading: Icon(Icons.settings, color: modernTheme.textColor),
                title: Text(
                  'Chat settings',
                  style: TextStyle(color: modernTheme.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to chat settings
                },
              ),
            ],
          ),
        );
      },
    );
  }
}