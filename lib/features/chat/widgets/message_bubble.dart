// lib/features/chat/widgets/message_bubble.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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

    final isMe = message.senderUID == currentUser.uid;
    
    // Check if the message is deleted
    final isDeletedForEveryone = message.isDeletedForEveryone;
    final isDeletedForMe = message.isDeletedFor(currentUser.uid);
    
    if (isDeletedForEveryone) {
      return _buildDeletedForEveryoneMessage(context);
    }
    
    if (isDeletedForMe) {
      return _buildDeletedMessage(context, isMe);
    }

    final chatTheme = context.chatTheme;
    final modernTheme = context.modernTheme;
    
    return Dismissible(
      key: Key('message_${message.messageId}'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        onSwipe?.call(message);
        return false; // Don't actually dismiss
      },
      background: Container(
        color: modernTheme.primaryColor?.withOpacity(0.1),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16.0),
        child: Icon(
          Icons.reply,
          color: modernTheme.primaryColor,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Reply message preview if present
                  if (message.repliedMessage != null)
                    _buildReplyPreview(context, isMe),
                  
                  // Message bubble
                  Container(
                    decoration: BoxDecoration(
                      color: isMe 
                          ? chatTheme.senderBubbleColor 
                          : chatTheme.receiverBubbleColor,
                      borderRadius: isMe 
                          ? chatTheme.senderBubbleRadius 
                          : chatTheme.receiverBubbleRadius,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeletedMessage(BuildContext context, bool isMe) {
    final modernTheme = context.modernTheme;
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: isMe ? 48 : 8,
          right: isMe ? 8 : 48,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: modernTheme.surfaceVariantColor?.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: modernTheme.dividerColor?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.block,
              size: 16,
              color: modernTheme.textSecondaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              'This message was deleted',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontStyle: FontStyle.italic,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDeletedForEveryoneMessage(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: modernTheme.surfaceVariantColor?.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delete_outline,
              size: 14,
              color: modernTheme.textSecondaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              'This message was deleted',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontStyle: FontStyle.italic,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context, bool isMe) {
    final modernTheme = context.modernTheme;
    final chatTheme = context.chatTheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe 
            ? Colors.black.withOpacity(0.1) 
            : Colors.white.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(
          left: BorderSide(
            color: modernTheme.primaryColor ?? Colors.blue,
            width: 3,
          ),
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
                  ? chatTheme.senderTextColor 
                  : chatTheme.receiverTextColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, bool isMe) {
    final chatTheme = context.chatTheme;
    
    switch (message.messageType) {
      case MessageEnum.text:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: TextStyle(
                color: isMe 
                    ? chatTheme.senderTextColor 
                    : chatTheme.receiverTextColor,
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
                        ? chatTheme.senderTextColor?.withOpacity(0.6)
                        : chatTheme.receiverTextColor?.withOpacity(0.6),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        );
        
      case MessageEnum.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: message.message,
            placeholder: (context, url) => Container(
              height: 200,
              color: Colors.grey.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              height: 200,
              color: Colors.grey.withOpacity(0.3),
              child: const Center(child: Icon(Icons.error)),
            ),
            fit: BoxFit.cover,
            width: double.infinity,
            height: 200,
          ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Video',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        );
        
      case MessageEnum.audio:
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.play_arrow,
                color: isMe 
                    ? chatTheme.senderTextColor 
                    : chatTheme.receiverTextColor,
              ),
              Expanded(
                child: Slider(
                  value: 0.0,
                  onChanged: (value) {},
                  activeColor: isMe 
                      ? chatTheme.senderTextColor 
                      : chatTheme.receiverTextColor,
                ),
              ),
              Text(
                '0:00',
                style: TextStyle(
                  color: isMe 
                      ? chatTheme.senderTextColor 
                      : chatTheme.receiverTextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
        
      case MessageEnum.file:
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.insert_drive_file,
                color: isMe 
                    ? chatTheme.senderTextColor 
                    : chatTheme.receiverTextColor,
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
                            ? chatTheme.senderTextColor 
                            : chatTheme.receiverTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Tap to download',
                      style: TextStyle(
                        color: isMe 
                            ? chatTheme.senderTextColor?.withOpacity(0.7) 
                            : chatTheme.receiverTextColor?.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case MessageEnum.location:
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                color: isMe 
                    ? chatTheme.senderTextColor 
                    : chatTheme.receiverTextColor,
                size: 30,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location',
                      style: TextStyle(
                        color: isMe 
                            ? chatTheme.senderTextColor 
                            : chatTheme.receiverTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Tap to view',
                      style: TextStyle(
                        color: isMe 
                            ? chatTheme.senderTextColor?.withOpacity(0.7) 
                            : chatTheme.receiverTextColor?.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case MessageEnum.contact:
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.person,
                color: isMe 
                    ? chatTheme.senderTextColor 
                    : chatTheme.receiverTextColor,
                size: 30,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact',
                      style: TextStyle(
                        color: isMe 
                            ? chatTheme.senderTextColor 
                            : chatTheme.receiverTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      message.message.isNotEmpty ? message.message : 'Contact info',
                      style: TextStyle(
                        color: isMe 
                            ? chatTheme.senderTextColor?.withOpacity(0.7) 
                            : chatTheme.receiverTextColor?.withOpacity(0.7),
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
                ? chatTheme.senderTextColor 
                : chatTheme.receiverTextColor,
            fontSize: 16,
          ),
        );
    }
  }
  
  String _getEditTimeText() {
    if (message.editedAt == null) return '';
    
    try {
      final editTime = DateTime.fromMillisecondsSinceEpoch(int.parse(message.editedAt!));
      final now = DateTime.now();
      final difference = now.difference(editTime);
      
      if (difference.inMinutes < 1) {
        return 'just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else {
        return DateFormat('MMM d').format(editTime);
      }
    } catch (e) {
      return '';
    }
  }
  
  Widget _buildReactionsBar(BuildContext context, bool isMe) {
    final chatTheme = context.chatTheme;
    
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
                        ? chatTheme.senderTextColor?.withOpacity(0.7)
                        : chatTheme.receiverTextColor?.withOpacity(0.7),
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
    final chatTheme = context.chatTheme;
    
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
            color: chatTheme.timestampColor,
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
    final chatTheme = context.chatTheme;
    
    IconData iconData;
    Color iconColor = chatTheme.timestampColor ?? Colors.grey;
    
    switch (message.messageStatus) {
      case MessageStatus.sending:
        iconData = Icons.access_time;
        break;
      case MessageStatus.sent:
        iconData = Icons.done;
        break;
      case MessageStatus.delivered:
        iconData = Icons.done_all;
        break;
      case MessageStatus.read:
        iconData = Icons.done_all;
        iconColor = Colors.blue;
        break;
      case MessageStatus.failed:
        iconData = Icons.error_outline;
        iconColor = Colors.red;
        break;
    }

    return Icon(
      iconData,
      color: iconColor,
      size: 12,
    );
  }
}