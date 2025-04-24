import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/models/message_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/features/chat/widgets/display_message_type.dart';
import 'package:textgb/features/chat/widgets/message_reply_preview.dart';

class AlignMessageLeftWidget extends StatelessWidget {
  const AlignMessageLeftWidget({
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
    final receiverBubbleColor = chatTheme.receiverBubbleColor ?? Colors.white;
    final receiverTextColor = chatTheme.receiverTextColor ?? Colors.black;
    final timestampColor = chatTheme.timestampColor ?? modernTheme.textTertiaryColor ?? Colors.grey;
    
    // Format time
    final DateTime timeToUse = message.timeSent ?? DateTime.now();
    final time = formatDate(timeToUse, [hh, ':', nn, ' ', am]);
    
    final isReplying = message.repliedTo.isNotEmpty;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, right: 64.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Padding(
            padding: const EdgeInsets.only(right: 8.0, top: 2.0),
            child: userImageWidget(
              imageUrl: message.senderImage,
              radius: 18,
              onTap: () {},
            ),
          ),
          
          // Message content column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show sender name if it's a group chat
                if (isGroupChat)
                  Padding(
                    padding: const EdgeInsets.only(left: 12.0, bottom: 2.0),
                    child: Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: 12,
                        color: modernTheme.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                
                // Message bubble with content
                Container(
                  decoration: BoxDecoration(
                    color: receiverBubbleColor,
                    borderRadius: chatTheme.receiverBubbleRadius ?? BorderRadius.circular(4.0),
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
                        color: receiverTextColor,
                        isReply: false,
                        viewOnly: viewOnly,
                      ),
                    ],
                  ),
                ),
                
                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(left: 12.0, top: 4.0),
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