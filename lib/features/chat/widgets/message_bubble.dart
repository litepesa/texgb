// lib/features/chat/widgets/message_bubble.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class MessageBubble extends ConsumerWidget {
  final MessageModel message;
  final UserModel contact;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.contact,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const SizedBox.shrink();

    // Check if the message is from the current user
    final isMe = message.senderUID == currentUser.uid;
    
    // Check if the message is deleted for the current user
    final isDeleted = message.deletedBy.contains(currentUser.uid);
    
    if (isDeleted) {
      return _buildDeletedMessage(context, isMe);
    }

    // Get bubble styles from theme
    final chatTheme = context.chatTheme;
    final borderRadius = isMe 
        ? BorderRadius.circular(16) // Use fixed radius instead of theme
        : BorderRadius.circular(16);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            margin: EdgeInsets.only(
              top: 4,
              bottom: 4,
              left: isMe ? 48 : 8,
              right: isMe ? 8 : 48,
            ),
            decoration: BoxDecoration(
              color: isMe 
                  ? chatTheme.senderBubbleColor 
                  : chatTheme.receiverBubbleColor,
              borderRadius: borderRadius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reply message if present
                if (message.repliedMessage != null)
                  _buildReplyPreview(context, isMe),
                
                // Message content
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                  child: _buildMessageContent(context, isMe),
                ),
                
                // Timestamp and seen status
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 4),
                    child: _buildTimestampAndSeen(context, isMe),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeletedMessage(BuildContext context, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: isMe ? 48 : 8,
          right: isMe ? 8 : 48,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: context.modernTheme.surfaceVariantColor?.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.modernTheme.dividerColor ?? Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(
          'This message was deleted',
          style: TextStyle(
            color: context.modernTheme.textSecondaryColor,
            fontStyle: FontStyle.italic,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context, bool isMe) {
    final modernTheme = context.modernTheme;
    
    // Check if this is a status reply
    final bool isStatusReply = message.repliedMessage != null && 
                              message.repliedMessage!.contains("status") &&
                              message.statusContext != null;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isMe 
            ? Colors.black.withOpacity(0.1) 
            : Colors.white.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status thumbnail (only if this is a status reply with a thumbnail)
          if (isStatusReply && message.statusContext != null && message.statusContext!.isNotEmpty)
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 8, bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isMe 
                      ? Colors.black.withOpacity(0.1) 
                      : Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: CachedNetworkImage(
                imageUrl: message.statusContext!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: modernTheme.primaryColor!.withOpacity(0.2),
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.image_not_supported,
                  color: modernTheme.textSecondaryColor,
                  size: 16,
                ),
              ),
            ),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${message.repliedTo == contact.uid ? contact.name : 'yourself'}',
                  style: TextStyle(
                    color: modernTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.repliedMessage ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isMe 
                        ? context.chatTheme.senderTextColor 
                        : context.chatTheme.receiverTextColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 1,
                  color: isMe
                      ? Colors.black.withOpacity(0.1)
                      : Colors.white.withOpacity(0.1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, bool isMe) {
    switch (message.messageType) {
      case MessageEnum.text:
        return Text(
          message.message,
          style: TextStyle(
            color: isMe 
                ? context.chatTheme.senderTextColor 
                : context.chatTheme.receiverTextColor,
            fontSize: 16,
          ),
        );
        
      case MessageEnum.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: message.message,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: Colors.grey.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: Colors.grey.withOpacity(0.3),
                  child: const Center(
                    child: Icon(Icons.error),
                  ),
                ),
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
              ),
            ),
          ],
        );
        
      case MessageEnum.video:
        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.play_circle_fill,
                color: Colors.white,
                size: 50,
              ),
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Video',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
        
      case MessageEnum.audio:
        return Container(
          padding: const EdgeInsets.symmetric(
            vertical: 8,
          ),
          child: Row(
            children: [
              Icon(
                Icons.play_arrow,
                color: isMe 
                    ? context.chatTheme.senderTextColor 
                    : context.chatTheme.receiverTextColor,
              ),
              Expanded(
                child: Slider(
                  value: 0.0,
                  onChanged: (value) {},
                  activeColor: isMe 
                      ? context.chatTheme.senderTextColor 
                      : context.chatTheme.receiverTextColor,
                ),
              ),
              Text(
                '0:00',
                style: TextStyle(
                  color: isMe 
                      ? context.chatTheme.senderTextColor 
                      : context.chatTheme.receiverTextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
        
      case MessageEnum.file:
        return Container(
          padding: const EdgeInsets.symmetric(
            vertical: 8,
          ),
          child: Row(
            children: [
              Icon(
                Icons.insert_drive_file,
                color: isMe 
                    ? context.chatTheme.senderTextColor 
                    : context.chatTheme.receiverTextColor,
                size: 30,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Document',
                      style: TextStyle(
                        color: isMe 
                            ? context.chatTheme.senderTextColor 
                            : context.chatTheme.receiverTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Tap to download',
                      style: TextStyle(
                        color: isMe 
                            ? context.chatTheme.senderTextColor?.withOpacity(0.7) 
                            : context.chatTheme.receiverTextColor?.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        
      default:
        return Text(
          message.message,
          style: TextStyle(
            color: isMe 
                ? context.chatTheme.senderTextColor 
                : context.chatTheme.receiverTextColor,
            fontSize: 16,
          ),
        );
    }
  }

  Widget _buildTimestampAndSeen(BuildContext context, bool isMe) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(
      int.parse(message.timeSent),
    );
    
    final timeStr = DateFormat('HH:mm').format(dateTime);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          timeStr,
          style: TextStyle(
            color: context.chatTheme.timestampColor,
            fontSize: 10,
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 4),
          Icon(
            message.isSeen ? Icons.done_all : Icons.done,
            color: message.isSeen ? Colors.blue : context.chatTheme.timestampColor,
            size: 12,
          ),
        ],
      ],
    );
  }
}