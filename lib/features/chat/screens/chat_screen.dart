// lib/features/chat/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class ChatScreen extends StatefulWidget {
  final String chatName;
  final String chatAvatar;

  const ChatScreen({
    super.key,
    required this.chatName,
    required this.chatAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    // Add some dummy messages
    _messages.addAll([
      {
        'text': 'Hey! How are you doing?',
        'isMine': false,
        'time': '10:30 AM',
      },
      {
        'text': 'I\'m doing great! Thanks for asking 😊',
        'isMine': true,
        'time': '10:32 AM',
      },
      {
        'text': 'That\'s awesome! Want to grab coffee later?',
        'isMine': false,
        'time': '10:33 AM',
      },
      {
        'text': 'Sure! What time works for you?',
        'isMine': true,
        'time': '10:35 AM',
      },
    ]);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'text': _messageController.text,
        'isMine': true,
        'time': 'Just now',
      });
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;

    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: modernTheme.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: modernTheme.textColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: modernTheme.primaryColor?.withOpacity(0.1),
              child: Text(
                widget.chatName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: modernTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chatName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: modernTheme.textColor,
                    ),
                  ),
                  Text(
                    'Online',
                    style: TextStyle(
                      fontSize: 12,
                      color: modernTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.videocam_outlined,
              color: modernTheme.textColor,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              Icons.call_outlined,
              color: modernTheme.textColor,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: modernTheme.textColor,
            ),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(
            height: 0.5,
            color: modernTheme.dividerColor,
          ),
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(
                  _messages[index],
                  modernTheme,
                );
              },
            ),
          ),
          // Message input
          _buildMessageInput(modernTheme),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    Map<String, dynamic> message,
    ModernThemeExtension modernTheme,
  ) {
    final isMine = message['isMine'] as bool;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: modernTheme.primaryColor?.withOpacity(0.1),
              child: Text(
                widget.chatName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: modernTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isMine
                    ? modernTheme.primaryColor
                    : modernTheme.surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMine
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: isMine
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['text'],
                    style: TextStyle(
                      fontSize: 15,
                      color: isMine ? Colors.white : modernTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message['time'],
                    style: TextStyle(
                      fontSize: 11,
                      color: isMine
                          ? Colors.white.withOpacity(0.7)
                          : modernTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMine) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildMessageInput(ModernThemeExtension modernTheme) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        border: Border(
          top: BorderSide(
            color: modernTheme.dividerColor!,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: modernTheme.backgroundColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: modernTheme.dividerColor!,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color: modernTheme.textSecondaryColor,
                        ),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(
                        color: modernTheme.textColor,
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.attach_file,
                      color: modernTheme.textSecondaryColor,
                    ),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.camera_alt_outlined,
                      color: modernTheme.textSecondaryColor,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: modernTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.send,
                color: Colors.white,
              ),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}