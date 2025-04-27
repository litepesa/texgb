// lib/features/chat/widgets/align_message_right_widget.dart

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
    // Get theme colors from ChatThemeExtension
    final chatTheme = context.chatTheme;
    final modernTheme = context.modernTheme;
    final responsiveTheme = context.responsiveTheme;
    
    // Get colors from the theme extensions
    final senderBubbleColor = chatTheme.senderBubbleColor ?? const Color(0xFF95EC69);
    final senderTextColor = chatTheme.senderTextColor ?? Colors.black;
    final timestampColor = chatTheme.timestampColor ?? modernTheme.textTertiaryColor ?? Colors.grey;
    
    // Format time
    final DateTime timeToUse = message.timeSent ?? DateTime.now();
    final time = formatDate(timeToUse, [hh, ':', nn, ' ', am]);
    
    final isReplying = message.repliedTo.isNotEmpty;
    
    // Get the reactions count
    final hasReactions = message.reactions.isNotEmpty;
    
    // Define the rounded rectangle border radius
    final BorderRadius roundedRectangleBorder = BorderRadius.only(
      topLeft: Radius.circular(16.0),
      topRight: Radius.circular(4.0),
      bottomLeft: Radius.circular(16.0),
      bottomRight: Radius.circular(16.0),
    );
    
    // Create gradient if in dark mode
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final BoxDecoration bubbleDecoration = isDarkMode
        ? BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF115740), Color(0xFF064E3B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          )
        : BoxDecoration(
            color: senderBubbleColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          );
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: responsiveTheme.compactSpacing * 1.5, 
        left: MediaQuery.of(context).size.width * 0.2,
        right: responsiveTheme.compactSpacing,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Message bubble with content
          Container(
            decoration: bubbleDecoration,
            padding: message.messageType == MessageEnum.text
              ? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0)
              : const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reply preview if applicable
                if (isReplying)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: MessageReplyPreview(
                      message: message,
                      viewOnly: viewOnly,
                    ),
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
          
          // Timestamp and reactions row
          Padding(
            padding: const EdgeInsets.only(top: 4.0, right: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Display reaction count if any
                if (hasReactions)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          size: 12,
                          color: modernTheme.textSecondaryColor,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          message.reactions.length.toString(),
                          style: TextStyle(
                            fontSize: 11,
                            color: modernTheme.textSecondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: timestampColor,
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