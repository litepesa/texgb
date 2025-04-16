import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/widgets/stacked_reactions.dart';
import 'package:provider/provider.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/models/message_model.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/widgets/display_message_type.dart';
import 'package:textgb/widgets/message_reply_preview.dart';

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
    
    final padding = messageReactions.isNotEmpty
        ? const EdgeInsets.only(left: 20.0, bottom: 25.0)
        : const EdgeInsets.only(bottom: 0.0);

    bool messageSeen() {
      final uid = context.read<AuthenticationProvider>().userModel?.uid ?? '';
      if (uid.isEmpty) return false;
      
      bool isSeen = false;
      if (isGroupChat) {
        List<String> isSeenByList = List<String>.from(message.isSeenBy); // Create a copy
        if (isSeenByList.contains(uid)) {
          // remove our uid then check again
          isSeenByList.remove(uid);
        }
        isSeen = isSeenByList.isNotEmpty;
      } else {
        isSeen = message.isSeen;
      }

      return isSeen;
    }

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
          minWidth: 100, // Add minimum width
        ),
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
                    bottomLeft: Radius.circular(15),
                  ),
                ),
                color: Colors.deepPurple,
                child: Padding(
                  padding: message.messageType == MessageEnum.text
                      ? const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 10.0)
                      : const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 10.0),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(), // Fix scroll behavior
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
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
                          color: Colors.white,
                          isReply: false,
                          viewOnly: viewOnly,
                        ),
                        const SizedBox(height: 4), // Add spacing
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              time,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Icon(
                              messageSeen() ? Icons.done_all : Icons.done,
                              color:
                                  messageSeen() ? Colors.blue : Colors.white60,
                              size: 15,
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (messageReactions.isNotEmpty)
              Positioned(
                bottom: 4,
                right: 30,
                child: StackedReactions(
                  reactions: messageReactions,
                ),
              )
          ],
        ),
      ),
    );
  }
}