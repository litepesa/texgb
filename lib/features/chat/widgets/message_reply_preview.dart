import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/models/message_model.dart';
import 'package:textgb/models/message_reply_model.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
import 'package:textgb/features/chat/widgets/display_message_type.dart';

class MessageReplyPreview extends StatelessWidget {
  const MessageReplyPreview({
    super.key,
    this.replyMessageModel,
    this.message,
    this.viewOnly = false,
  });

  final MessageReplyModel? replyMessageModel;
  final MessageModel? message;
  final bool viewOnly;

  @override
  Widget build(BuildContext context) {
    // Check if both are null and provide a fallback
    if (replyMessageModel == null && message == null) {
      return const SizedBox(); // Return an empty widget if both are null
    }

    // Safely access messageType with null checks
    final MessageEnum? type = replyMessageModel != null 
        ? replyMessageModel?.messageType 
        : message?.messageType;
        
    if (type == null) {
      return const SizedBox(); // Return an empty widget if type is null
    }

    final chatProvider = context.read<ChatProvider>();

    final intrisitPadding = replyMessageModel != null
        ? const EdgeInsets.all(10)
        : const EdgeInsets.only(top: 5, right: 5, bottom: 5);

    // Safely access colors with null checks
    final Color decorationColor = replyMessageModel != null
        ? Theme.of(context).textTheme.titleLarge?.color?.withOpacity(0.1) 
            ?? Colors.grey.withOpacity(0.1)
        : Theme.of(context).primaryColorDark.withOpacity(0.2);
        
    return IntrinsicHeight(
      child: Container(
        padding: intrisitPadding,
        decoration: BoxDecoration(
          color: decorationColor,
          borderRadius: replyMessageModel != null
              ? BorderRadius.circular(20)
              : BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              decoration: const BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
            const SizedBox(width: 8),
            buildNameAndMessage(type, context),
            replyMessageModel != null ? const Spacer() : const SizedBox(),
            replyMessageModel != null
                ? closeButton(chatProvider, context)
                : const SizedBox(),
          ],
        ),
      ),
    );
  }

  InkWell closeButton(ChatProvider chatProvider, BuildContext context) {
    final Color? borderColor = Theme.of(context).textTheme.titleLarge?.color;
    
    return InkWell(
      onTap: () {
        chatProvider.setMessageReplyModel(null);
      },
      child: Container(
          decoration: BoxDecoration(
            color: borderColor?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: borderColor ?? Colors.grey,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(2),
          child: const Icon(Icons.close)),
    );
  }

  Widget buildNameAndMessage(MessageEnum type, BuildContext context) {
    // Check if we have a status thumbnail
    final bool hasStatusThumbnail = (replyMessageModel != null && 
                                    replyMessageModel!.statusThumbnailUrl != null) ||
                                   (message != null && 
                                    message!.statusThumbnailUrl != null);
    
    // Get thumbnail URL from either source
    final String? thumbnailUrl = replyMessageModel?.statusThumbnailUrl ?? 
                                message?.statusThumbnailUrl;
    
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          getTitle(),
          const SizedBox(height: 5),
          
          // Show status thumbnail if available
          if (hasStatusThumbnail && thumbnailUrl != null)
            Container(
              height: 60,
              width: 100,
              margin: const EdgeInsets.only(top: 4, bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.grey.withOpacity(0.2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Center(
                    child: Icon(
                      _getStatusTypeIcon(type),
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                  errorWidget: (context, url, error) => Center(
                    child: Icon(
                      _getStatusTypeIcon(type),
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          
          if (replyMessageModel != null)
            messageToShow(
              type: type,
              message: replyMessageModel!.message,
            )
          else if (message != null)
            DisplayMessageType(
              message: message!.repliedMessage,
              type: message!.repliedMessageType ?? MessageEnum.text, // Provide fallback
              color: Colors.white,
              isReply: true,
              maxLines: 1,
              overFlow: TextOverflow.ellipsis,
              viewOnly: viewOnly,
            )
          else
            const Text('No message content', style: TextStyle(fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget getTitle() {
    if (replyMessageModel != null) {
      bool isMe = replyMessageModel!.isMe;
      return Text(
        isMe ? 'You' : replyMessageModel!.senderName ?? 'Unknown', // Add fallback
        style: GoogleFonts.openSans(
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      );
    } else if (message != null) {
      return Text(
        message!.repliedTo ?? 'Unknown', // Add fallback
        style: GoogleFonts.openSans(
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      );
    } else {
      // Fallback if both replyMessageModel and message are null
      return const Text(
        'Unknown',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      );
    }
  }
  
  // Helper method to determine icon based on message type
  IconData _getStatusTypeIcon(MessageEnum type) {
    switch (type) {
      case MessageEnum.video:
        return Icons.videocam;
      case MessageEnum.image:
        return Icons.image;
      case MessageEnum.audio:
        return Icons.headphones;
      case MessageEnum.text:
      default:
        return Icons.chat;
    }
  }
  
  Widget messageToShow({required MessageEnum type, required String message}) {
    return DisplayMessageType(
      message: message,
      type: type,
      color: Colors.white,
      isReply: true,
      maxLines: 1,
      overFlow: TextOverflow.ellipsis,
      viewOnly: viewOnly,
    );
  }
}