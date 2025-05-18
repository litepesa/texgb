// lib/features/chat/widgets/chat_input.dart
import 'package:flutter/material.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttachmentTap;
  final bool isEditing; // New parameter for edit mode
  final VoidCallback? onCancelEditing; // New parameter for canceling edit

  const ChatInput({
    Key? key,
    required this.controller,
    required this.onSend,
    required this.onAttachmentTap,
    this.isEditing = false, // Default is not editing
    this.onCancelEditing,
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 4,
        ),
        margin: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: 8 + bottomPadding / 2,
          top: 4,
        ),
        decoration: BoxDecoration(
          color: widget.isEditing 
              ? Colors.blue.withOpacity(0.1) // Different color for editing mode
              : chatTheme.inputBackgroundColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Attachment button (hide when editing)
            if (!widget.isEditing)
              Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: Icon(
                    Icons.attach_file_rounded,
                    color: modernTheme.primaryColor?.withOpacity(0.7),
                    size: 24,
                  ),
                  onPressed: widget.onAttachmentTap,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  splashRadius: 24,
                ),
              ),
            
            // Cancel edit button (show only when editing)
            if (widget.isEditing)
              Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.red.withOpacity(0.7),
                    size: 24,
                  ),
                  onPressed: widget.onCancelEditing,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  splashRadius: 24,
                ),
              ),
            
            // Message input field
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
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
                    hintText: widget.isEditing ? 'Edit message' : 'Message',
                    hintStyle: TextStyle(
                      color: modernTheme.textSecondaryColor?.withOpacity(0.7),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    isDense: true,
                    alignLabelWithHint: true,
                  ),
                  textAlignVertical: TextAlignVertical.center,
                  cursorColor: widget.isEditing ? Colors.blue : modernTheme.primaryColor,
                  cursorWidth: 1.5,
                  cursorHeight: 20,
                ),
              ),
            ),
            
            // Send or voice button
            Padding(
              padding: const EdgeInsets.only(bottom: 2, right: 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _showSendButton ? 70 : 40,
                height: 40,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _showSendButton
                      ? ElevatedButton(
                          key: const ValueKey('send_button'),
                          onPressed: widget.onSend,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.isEditing ? Colors.blue : modernTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            minimumSize: const Size(70, 40),
                          ),
                          child: Text(
                            widget.isEditing ? 'Save' : 'Send',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : Container(
                          key: const ValueKey('mic_button'),
                          decoration: BoxDecoration(
                            color: modernTheme.surfaceVariantColor?.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.mic_rounded,
                              color: modernTheme.primaryColor,
                              size: 22,
                            ),
                            onPressed: () {
                              // TODO: Implement voice recording
                            },
                            padding: EdgeInsets.zero,
                            splashRadius: 24,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}