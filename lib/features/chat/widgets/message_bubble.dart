// Enhanced Message Bubble with WhatsApp-like Status Reply UI
// lib/features/chat/widgets/message_bubble.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class MessageBubble extends ConsumerWidget {
  final MessageModel message;
  final UserModel contact;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Function(MessageModel)? onSwipe;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.contact,
    this.onTap,
    this.onLongPress,
    this.onSwipe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const SizedBox.shrink();

    // Check if the message is from the current user
    final isMe = message.senderUID == currentUser.uid;
    
    // Check if the message is deleted for everyone or just for the current user
    final isDeletedForEveryone = message.isDeletedForEveryone;
    final isDeletedForMe = message.deletedBy.contains(currentUser.uid);
    
    if (isDeletedForEveryone) {
      return _buildDeletedForEveryoneMessage(context);
    }
    
    if (isDeletedForMe) {
      return _buildDeletedMessage(context, isMe);
    }

    // Get bubble styles from theme
    final chatTheme = context.chatTheme;
    final borderRadius = isMe 
        ? BorderRadius.circular(16)
        : BorderRadius.circular(16);
    
    // Build swipeable container for reply functionality
    return Dismissible(
      key: Key('message_${message.messageId}'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        if (onSwipe != null) {
          onSwipe!(message);
        }
        return false; // Don't actually dismiss the item
      },
      background: Container(
        color: Colors.blue.withOpacity(0.2),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16.0),
        child: const Icon(
          Icons.reply,
          color: Colors.blue,
        ),
      ),
      child: Align(
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
                  // Status reply preview if present
                  if (message.isStatusReply)
                    _buildStatusReplyPreview(context, isMe),
                  
                  // Regular reply message if present and not status reply
                  if (message.repliedMessage != null && !message.isStatusReply)
                    _buildReplyPreview(context, isMe),
                  
                  // Message content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                    child: _buildMessageContent(context, isMe),
                  ),
                  
                  // Reactions if present
                  if (message.reactions.isNotEmpty)
                    _buildReactionsBar(context, isMe),
                  
                  // Timestamp and status
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 4),
                      child: _buildTimestampAndStatus(context, isMe),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusReplyPreview(BuildContext context, bool isMe) {
    final modernTheme = context.modernTheme;
    final chatTheme = context.chatTheme;
    
    // Determine status type icon and preview text
    IconData statusIcon;
    String statusPreview;
    Color statusIconColor = modernTheme.primaryColor!;
    
    switch (message.statusType!) {
      case StatusType.text:
        statusIcon = Icons.text_fields;
        statusPreview = message.repliedMessage ?? 'Text status';
        break;
      case StatusType.image:
        statusIcon = Icons.image;
        statusPreview = 'Photo';
        statusIconColor = Colors.green;
        break;
      case StatusType.video:
        statusIcon = Icons.videocam;
        statusPreview = 'Video';
        statusIconColor = Colors.red;
        break;
      case StatusType.link:
        statusIcon = Icons.link;
        statusPreview = 'Link';
        statusIconColor = Colors.blue;
        break;
    }
    
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: isMe 
            ? Colors.black.withOpacity(0.1) 
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMe 
              ? Colors.black.withOpacity(0.1) 
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with "Replied to status" label
          Container(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
            child: Row(
              children: [
                Icon(
                  Icons.reply,
                  size: 14,
                  color: modernTheme.primaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'Replied to status',
                  style: TextStyle(
                    color: modernTheme.primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Status content preview
          Container(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status thumbnail or icon
                if (message.statusThumbnailUrl != null && 
                    message.statusThumbnailUrl!.isNotEmpty &&
                    (message.statusType == StatusType.image || 
                     message.statusType == StatusType.video))
                  Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isMe 
                            ? Colors.black.withOpacity(0.1) 
                            : Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: message.statusThumbnailUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: modernTheme.surfaceColor!.withOpacity(0.3),
                            child: const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: modernTheme.surfaceColor!.withOpacity(0.3),
                            child: Icon(
                              statusIcon,
                              color: statusIconColor,
                              size: 20,
                            ),
                          ),
                        ),
                        // Video play icon overlay
                        if (message.statusType == StatusType.video)
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                else
                  // Icon for text/link status
                  Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: statusIconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: statusIconColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      statusIcon,
                      color: statusIconColor,
                      size: 20,
                    ),
                  ),
                
                // Status content text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status type and preview
                      Text(
                        statusPreview,
                        maxLines: message.statusType == StatusType.text ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isMe 
                              ? chatTheme.senderTextColor 
                              : chatTheme.receiverTextColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      
                      // Status caption if available
                      if (message.statusCaption != null && 
                          message.statusCaption!.isNotEmpty &&
                          message.statusType != StatusType.text) ...[
                        const SizedBox(height: 2),
                        Text(
                          message.statusCaption!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isMe 
                                ? chatTheme.senderTextColor?.withOpacity(0.7) 
                                : chatTheme.receiverTextColor?.withOpacity(0.7),
                            fontSize: 11,
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
  
  Widget _buildDeletedForEveryoneMessage(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: 8,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'This message was deleted',
          style: TextStyle(
            color: context.modernTheme.textSecondaryColor,
            fontStyle: FontStyle.italic,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context, bool isMe) {
    final modernTheme = context.modernTheme;
    
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
    );
  }

  Widget _buildMessageContent(BuildContext context, bool isMe) {
    final modernTheme = context.modernTheme;
    
    // Show edited indicator if applicable
    Widget messageWidget;
    
    switch (message.messageType) {
      case MessageEnum.text:
        messageWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: TextStyle(
                color: isMe 
                    ? context.chatTheme.senderTextColor 
                    : context.chatTheme.receiverTextColor,
                fontSize: 16,
              ),
            ),
            if (message.isEdited)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'edited ${_getEditTimeText()}',
                  style: TextStyle(
                    color: isMe 
                        ? context.chatTheme.senderTextColor?.withOpacity(0.6)
                        : context.chatTheme.receiverTextColor?.withOpacity(0.6),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        );
        break;
        
      case MessageEnum.image:
        messageWidget = Column(
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
        break;
        
      case MessageEnum.video:
        messageWidget = Container(
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
        break;
        
      case MessageEnum.audio:
        messageWidget = Container(
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
        break;
        
      case MessageEnum.file:
        messageWidget = Container(
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
        break;
        
      default:
        messageWidget = Text(
          message.message,
          style: TextStyle(
            color: isMe 
                ? context.chatTheme.senderTextColor 
                : context.chatTheme.receiverTextColor,
            fontSize: 16,
          ),
        );
    }
    
    return messageWidget;
  }
  
  String _getEditTimeText() {
    if (message.editedAt == null) return '';
    
    final editTime = DateTime.fromMillisecondsSinceEpoch(int.parse(message.editedAt!));
    final now = DateTime.now();
    
    if (now.difference(editTime).inMinutes < 1) {
      return 'just now';
    } else if (now.difference(editTime).inHours < 1) {
      return '${now.difference(editTime).inMinutes}m ago';
    } else if (now.difference(editTime).inDays < 1) {
      return '${now.difference(editTime).inHours}h ago';
    } else {
      return DateFormat('MMM d').format(editTime);
    }
  }
  
  Widget _buildReactionsBar(BuildContext context, bool isMe) {
    // Group reactions by emoji
    Map<String, int> reactionCounts = {};
    for (var reaction in message.reactions.values) {
      final emoji = reaction['emoji'] ?? '👍';
      reactionCounts[emoji] = (reactionCounts[emoji] ?? 0) + 1;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4, left: 12, right: 12),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: reactionCounts.entries.map((entry) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 4),
                Text(
                  entry.value.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isMe 
                        ? context.chatTheme.senderTextColor?.withOpacity(0.7)
                        : context.chatTheme.receiverTextColor?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimestampAndStatus(BuildContext context, bool isMe) {
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
          _buildMessageStatusIcon(context),
        ],
      ],
    );
  }
  
  Widget _buildMessageStatusIcon(BuildContext context) {
    // Use different icons and colors based on message status
    IconData iconData;
    Color iconColor = context.chatTheme.timestampColor ?? Colors.grey;
    String tooltipMessage;

    switch (message.messageStatus) {
      case MessageStatus.sending:
        iconData = Icons.access_time;
        tooltipMessage = 'Sending...';
        break;
      case MessageStatus.sent:
        iconData = Icons.done;
        tooltipMessage = 'Sent';
        break;
      case MessageStatus.delivered:
        iconData = Icons.done_all;
        tooltipMessage = 'Delivered';
        break;
      case MessageStatus.read:
        iconData = Icons.done_all;
        iconColor = Colors.blue;
        tooltipMessage = 'Read';
        break;
      case MessageStatus.failed:
        iconData = Icons.error_outline;
        iconColor = Colors.red;
        tooltipMessage = 'Failed to send';
        break;
      default:
        iconData = Icons.done;
        tooltipMessage = 'Sent';
    }

    return Tooltip(
      message: tooltipMessage,
      child: Icon(
        iconData,
        color: iconColor,
        size: 12,
      ),
    );
  }
}