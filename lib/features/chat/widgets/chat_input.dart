import 'package:flutter/material.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttachmentTap;

  const ChatInput({
    Key? key,
    required this.controller,
    required this.onSend,
    required this.onAttachmentTap,
  }) : super(key: key);

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  bool _showSendButton = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateSendButton);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateSendButton);
    super.dispose();
  }

  void _updateSendButton() {
    final shouldShowSend = widget.controller.text.isNotEmpty;
    if (shouldShowSend != _showSendButton) {
      setState(() {
        _showSendButton = shouldShowSend;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final chatTheme = context.chatTheme;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: 8 + MediaQuery.of(context).padding.bottom,
      ),
      color: chatTheme.inputBackgroundColor,
      child: Row(
        children: [
          // Attachment button
          IconButton(
            icon: Icon(
              Icons.attach_file,
              color: modernTheme.textSecondaryColor,
            ),
            onPressed: widget.onAttachmentTap,
          ),
          
          // Message input field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: modernTheme.surfaceVariantColor,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: widget.controller,
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 16,
                ),
                maxLines: 5,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message',
                  hintStyle: TextStyle(
                    color: modernTheme.textSecondaryColor?.withOpacity(0.7),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Send or voice button
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _showSendButton
                ? IconButton(
                    key: const ValueKey('send'),
                    icon: Icon(
                      Icons.send,
                      color: modernTheme.primaryColor,
                    ),
                    onPressed: widget.onSend,
                  )
                : IconButton(
                    key: const ValueKey('mic'),
                    icon: Icon(
                      Icons.mic,
                      color: modernTheme.textSecondaryColor,
                    ),
                    onPressed: () {
                      // TODO: Implement voice recording
                    },
                  ),
          ),
        ],
      ),
    );
  }
}