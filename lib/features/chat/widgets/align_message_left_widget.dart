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
    // Get theme colors from ChatThemeExtension
    final chatTheme = context.chatTheme;
    final modernTheme = context.modernTheme;
    final responsiveTheme = context.responsiveTheme;
    final animationTheme = context.animationTheme;
    
    // Get colors from the theme extensions
    final receiverBubbleColor = chatTheme.receiverBubbleColor ?? Colors.white;
    final receiverTextColor = chatTheme.receiverTextColor ?? Colors.black;
    final timestampColor = chatTheme.timestampColor ?? modernTheme.textTertiaryColor ?? Colors.grey;
    
    // Format time
    final DateTime timeToUse = message.timeSent ?? DateTime.now();
    final time = formatDate(timeToUse, [hh, ':', nn, ' ', am]);
    
    final isReplying = message.repliedTo.isNotEmpty;
    
    // Get the reactions count
    final hasReactions = message.reactions.isNotEmpty;
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: responsiveTheme.compactSpacing * 1.5, 
        right: MediaQuery.of(context).size.width * 0.2,
        left: responsiveTheme.compactSpacing,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar with animated container for hover effects
          AnimatedContainer(
            duration: animationTheme.shortDuration,
            curve: animationTheme.standardCurve,
            margin: const EdgeInsets.only(right: 8.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
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
                    padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
                    child: Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: 13,
                        color: modernTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                
                // Message bubble with content
                Container(
                  decoration: BoxDecoration(
                    color: receiverBubbleColor,
                    borderRadius: chatTheme.receiverBubbleRadius ?? BorderRadius.circular(18.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
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
                        color: receiverTextColor,
                        isReply: false,
                        viewOnly: viewOnly,
                      ),
                    ],
                  ),
                ),
                
                // Timestamp and reactions row
                Padding(
                  padding: const EdgeInsets.only(left: 12.0, top: 4.0, right: 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 11,
                          color: timestampColor,
                        ),
                      ),
                      
                      // Display reaction count if any
                      if (hasReactions) ...[
                        const SizedBox(width: 6),
                        Container(
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
                      ],
                    ],
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