import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class ChatInputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSendMessage;
  final VoidCallback onAttachmentTap;
  final VoidCallback onMicTap;
  final bool isRecording;
  final VoidCallback onCancelRecording;

  const ChatInputField({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.onSendMessage,
    required this.onAttachmentTap,
    required this.onMicTap,
    this.isRecording = false,
    required this.onCancelRecording,
  }) : super(key: key);

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  bool _showSendButton = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.isNotEmpty;
    if (_showSendButton != hasText) {
      setState(() {
        _showSendButton = hasText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final chatTheme = Theme.of(context).extension<ChatThemeExtension>()!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: modernTheme.surfaceColor,
          border: Border(
            top: BorderSide(
              color: modernTheme.dividerColor ?? Colors.grey.withOpacity(0.2),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Attachment button
            IconButton(
              icon: Icon(
                Icons.add,
                color: modernTheme.primaryColor,
              ),
              onPressed: widget.onAttachmentTap,
              splashRadius: 20,
            ),
            
            // Text input field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: chatTheme.inputBackgroundColor,
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(
                    color: isDarkMode ? Colors.transparent : Colors.grey.withOpacity(0.2),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                        child: TextField(
                          controller: widget.controller,
                          focusNode: widget.focusNode,
                          style: TextStyle(
                            color: modernTheme.textColor,
                            fontSize: 16.0,
                          ),
                          maxLines: 5,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Type a message',
                            hintStyle: TextStyle(
                              color: modernTheme.textSecondaryColor,
                              fontSize: 16.0,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                          ),
                        ),
                      ),
                    ),
                    
                    // Emoji button
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                      child: IconButton(
                        icon: Icon(
                          Icons.emoji_emotions_outlined,
                          color: modernTheme.textSecondaryColor,
                          size: 24.0,
                        ),
                        onPressed: () {
                          // Show emoji picker
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(width: 4.0),
            
            // Send/Mic button
            _showSendButton
                ? Container(
                    width: 44.0,
                    height: 44.0,
                    decoration: BoxDecoration(
                      color: modernTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20.0,
                      ),
                      onPressed: widget.onSendMessage,
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                    ),
                  )
                : Container(
                    width: 44.0,
                    height: 44.0,
                    decoration: BoxDecoration(
                      color: modernTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 20.0,
                      ),
                      onPressed: widget.onMicTap,
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}