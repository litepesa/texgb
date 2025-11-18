// lib/features/groups/widgets/group_message_bubble.dart
import 'package:flutter/material.dart';
import 'package:textgb/features/groups/models/group_message_model.dart';

class GroupMessageBubble extends StatelessWidget {
  final GroupMessageModel message;
  final bool isMe;
  final bool showSender;
  final VoidCallback? onDelete;

  const GroupMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showSender = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender name (for group messages from others)
          if (showSender && !isMe)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Text(
                message.displaySenderName,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // Message bubble
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Sender avatar (for messages from others)
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: message.senderImage != null
                        ? NetworkImage(message.senderImage!)
                        : null,
                    child: message.senderImage == null
                        ? Text(
                            _getInitials(message.displaySenderName),
                            style: const TextStyle(fontSize: 12),
                          )
                        : null,
                  ),
                ),

              // Message content
              Flexible(
                child: GestureDetector(
                  onLongPress: isMe ? _showMessageOptions : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isMe
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Media if present
                        if (message.hasMedia) _buildMediaContent(),

                        // Text message
                        if (message.messageText.isNotEmpty)
                          Text(
                            message.messageText,
                            style: TextStyle(
                              fontSize: 15,
                              color: isMe ? Colors.white : Colors.black87,
                            ),
                          ),

                        // Time and read status
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              message.formattedTime,
                              style: TextStyle(
                                fontSize: 11,
                                color: isMe
                                    ? Colors.white70
                                    : Colors.grey[600],
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              Icon(
                                message.readCount > 0
                                    ? Icons.done_all
                                    : Icons.done,
                                size: 14,
                                color: message.readCount > 0
                                    ? Colors.blue
                                    : Colors.white70,
                              ),
                              if (message.readCount > 1)
                                Text(
                                  ' ${message.readCount}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContent() {
    if (message.isImage) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            message.mediaUrl!,
            width: 200,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => Container(
              width: 200,
              height: 150,
              color: Colors.grey[400],
              child: const Icon(Icons.broken_image, size: 40),
            ),
          ),
        ),
      );
    } else if (message.isVideo) {
      return Container(
        width: 200,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.play_circle_outline,
          size: 50,
          color: Colors.white,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _showMessageOptions() {
    if (onDelete != null) {
      // TODO: Show bottom sheet with delete option
      onDelete!();
    }
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }
    return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'
        .toUpperCase();
  }
}
