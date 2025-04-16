import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/widgets/stacked_reactions.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/models/message_model.dart';
import 'package:textgb/utilities/global_methods.dart';
import 'package:textgb/widgets/display_message_type.dart';
import 'package:textgb/widgets/message_reply_preview.dart';

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
    // Safely handle potentially null timestamp
    final DateTime timeToUse = message.timeSent ?? DateTime.now();
    final time = formatDate(timeToUse, [hh, ':', nn, ' ', am]);
    
    final isReplying = message.repliedTo.isNotEmpty;
    
    // Get the reactions from the list - handle empty values safely
    final messageReactions = message.reactions.isNotEmpty 
        ? message.reactions.map((e) {
            final parts = e.split('=');
            return parts.length > 1 ? parts[1] : '';
          }).where((e) => e.isNotEmpty).toList()
        : <String>[];
    
    // check if its dark mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final padding = messageReactions.isNotEmpty
        ? const EdgeInsets.only(right: 20.0, bottom: 25.0)
        : const EdgeInsets.only(bottom: 0.0);
        
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
          minWidth: 100, // Set minimum width to ensure layout
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Add this to prevent row expansion
          crossAxisAlignment: CrossAxisAlignment.start, // Align to top
          children: [
            if (isGroupChat)
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: userImageWidget(
                  imageUrl: message.senderImage,
                  radius: 20,
                  onTap: () {},
                ),
              ),
            Flexible(
              child: Stack(
                clipBehavior: Clip.none, // Prevent clipping of stacked reactions
                children: [
                  Padding(
                    padding: padding,
                    child: Card(
                      elevation: 5,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                          bottomRight: Radius.circular(15),
                        ),
                      ),
                      color: Theme.of(context).cardColor,
                      child: Padding(
                        padding: message.messageType == MessageEnum.text
                            ? const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 10.0)
                            : const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 10.0),
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(), // Fix scroll behavior
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min, // Add this to prevent column expansion
                            children: [
                              if (isReplying) ...[
                                MessageReplyPreview(
                                  message: message,
                                  viewOnly: viewOnly,
                                )
                              ],
                              DisplayMessageType(
                                message: message.message,
                                type: message.messageType,
                                color: isDarkMode ? Colors.white : Colors.black,
                                isReply: false,
                                viewOnly: viewOnly,
                              ),
                              const SizedBox(height: 4), // Add spacing
                              Text(
                                time,
                                style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white60
                                        : Colors.grey.shade500,
                                    fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (messageReactions.isNotEmpty)
                    Positioned(
                      bottom: 0,
                      left: 50,
                      child: StackedReactions(
                        reactions: messageReactions,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}