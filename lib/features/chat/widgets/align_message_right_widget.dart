import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/models/message_model.dart';
import 'package:textgb/features/chat/widgets/display_message_type.dart';
import 'package:textgb/features/chat/widgets/message_reply_preview.dart';

class AlignMessageRightWidget extends StatelessWidget {
  const AlignMessageRightWidget({
    super.key,
    required this.message,
    this.viewOnly = false,
    required this.isGroupChat,
  });

  final MessageModel message;
  final bool viewOnly;
  final bool isGroupChat;

  @override
  Widget build(BuildContext context) {
    // Get theme colors from ChatThemeExtension instead of WeChatThemeExtension
    final chatTheme = context.chatTheme;
    final modernTheme = context.modernTheme;
    
    // Get colors from the theme extensions
    final senderBubbleColor = chatTheme.senderBubbleColor ?? const Color(0xFF95EC69);
    final senderTextColor = chatTheme.senderTextColor ?? Colors.black;
    final timestampColor = chatTheme.timestampColor ?? modernTheme.textTertiaryColor ?? Colors.grey;
    
    // Format time
    final DateTime timeToUse = message.timeSent ?? DateTime.now();
    final time = formatDate(timeToUse, [hh, ':', nn, ' ', am]);
    
    final isReplying = message.repliedTo.isNotEmpty;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 64.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message content column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Message bubble with content
                Container(
                  decoration: BoxDecoration(
                    color: senderBubbleColor,
                    borderRadius: chatTheme.senderBubbleRadius ?? BorderRadius.circular(4.0),
                  ),
                  padding: message.messageType == MessageEnum.text
                    ? const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0)
                    : const EdgeInsets.all(4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Reply preview if applicable
                      if (isReplying)
                        MessageReplyPreview(
                          message: message,
                          viewOnly: viewOnly,
                        ),
                      
                      // Message content
                      DisplayMessageType(
                        message: message.message,
                        type: message.messageType,
                        color: senderTextColor,
                        isReply: false,
                        viewOnly: viewOnly,
                      ),
                    ],
                  ),
                ),
                
                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(right: 12.0, top: 4.0),
                  child: Text(
                    time,
                    style: TextStyle(
                      fontSize: 11,
                      color: timestampColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}