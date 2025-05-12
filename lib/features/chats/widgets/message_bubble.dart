import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/chats/models/chat_message_model.dart';
import 'package:textgb/features/chats/providers/message_interaction_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/image_viewer.dart';
import 'package:textgb/shared/widgets/video_player_widget.dart';

class MessageBubble extends ConsumerStatefulWidget {
  final ChatMessageModel message;
  final VoidCallback onReplyTap;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.onReplyTap,
  }) : super(key: key);

  @override
  ConsumerState<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends ConsumerState<MessageBubble> {
  bool _showOptions = false;

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final chatTheme = Theme.of(context).extension<ChatThemeExtension>()!;
    final message = widget.message;
    
    // Determine bubble styling based on sender
    final isSender = message.isMe;
    final bubbleColor = isSender ? chatTheme.senderBubbleColor : chatTheme.receiverBubbleColor;
    final bubbleAlignment = isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleMargin = isSender 
        ? const EdgeInsets.only(left: 50, right: 8, bottom: 2)
        : const EdgeInsets.only(right: 50, left: 8, bottom: 2);
    final bubbleRadius = isSender ? chatTheme.senderBubbleRadius : chatTheme.receiverBubbleRadius;
    final textColor = isSender ? chatTheme.senderTextColor : chatTheme.receiverTextColor;
    
    // Format timestamp
    final messageTime = DateFormat('HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(message.timeSent),
    );

    return GestureDetector(
      onTap: () {
        setState(() {
          _showOptions = false;
        });
      },
      onLongPress: () {
        setState(() {
          _showOptions = !_showOptions;
        });
        HapticFeedback.mediumImpact();
      },
      child: Column(
        crossAxisAlignment: bubbleAlignment,
        children: [
          // Options menu if showing
          if (_showOptions)
            _buildOptionsMenu(isSender),
          
          Stack(
            children: [
              Container(
                margin: bubbleMargin,
                child: Column(
                  crossAxisAlignment: bubbleAlignment,
                  children: [
                    // Message content
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // User avatar for receiver messages
                        if (!isSender)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: userImageWidget(
                              imageUrl: message.senderImage,
                              radius: 16,
                              onTap: () {
                                // View profile
                              },
                            ),
                          ),
                        
                        // Message bubble
                        Flexible(
                          child: Container(
                            padding: _getBubblePadding(message.messageType),
                            decoration: BoxDecoration(
                              color: bubbleColor,
                              borderRadius: bubbleRadius,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Replied message if this is a reply
                                if (message.isReply)
                                  _buildReplyPreview(message),
                                
                                // Actual message content
                                _buildMessageContent(message, textColor),
                                
                                // Time and status indicators
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        messageTime,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: chatTheme.timestampColor,
                                        ),
                                      ),
                                      if (isSender)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 4),
                                          child: Icon(
                                            message.isSeen ? Icons.done_all : Icons.done,
                                            size: 14,
                                            color: message.isSeen 
                                                ? modernTheme.primaryColor
                                                : chatTheme.timestampColor,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Reactions (future implementation)
              // Positioned(...)
            ],
          ),
        ],
      ),
    );
  }

  EdgeInsets _getBubblePadding(MessageEnum messageType) {
    switch (messageType) {
      case MessageEnum.image:
      case MessageEnum.video:
        return const EdgeInsets.all(4);
      case MessageEnum.text:
      case MessageEnum.audio:
      case MessageEnum.file:
      case MessageEnum.location:
      case MessageEnum.contact:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    }
  }

  Widget _buildReplyPreview(ChatMessageModel message) {
    final modernTheme = context.modernTheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.repliedTo == message.senderUID ? 'You' : message.senderName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: modernTheme.primaryColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          message.repliedMessageType == MessageEnum.text
              ? Text(
                  message.repliedMessage ?? '',
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      message.repliedMessageType?.icon ?? Icons.help_outline,
                      size: 14,
                      color: modernTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      message.repliedMessageType?.displayName ?? 'Message',
                      style: TextStyle(
                        color: modernTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(ChatMessageModel message, Color? textColor) {
    switch (message.messageType) {
      case MessageEnum.text:
        return Text(
          message.message,
          style: TextStyle(
            fontSize: 16,
            color: textColor,
          ),
        );
        
      case MessageEnum.image:
        return _buildImageMessage(message);
        
      case MessageEnum.video:
        return _buildVideoMessage(message);
        
      case MessageEnum.audio:
        return _buildAudioMessage(message);
        
      case MessageEnum.file:
        return _buildFileMessage(message);
        
      case MessageEnum.location:
        return _buildLocationMessage(message);
        
      case MessageEnum.contact:
        return _buildContactMessage(message);
    }
  }

  Widget _buildImageMessage(ChatMessageModel message) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageViewer(imageUrl: message.mediaUrl ?? ''),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 200,
          height: 200,
          child: CachedNetworkImage(
            imageUrl: message.mediaUrl ?? '',
            fit: BoxFit.cover,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoMessage(ChatMessageModel message) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerWidget(videoUrl: message.mediaUrl ?? ''),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CachedNetworkImage(
                imageUrl: message.thumbnailUrl ?? '',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.video_file, size: 50),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              if (message.mediaDuration != null)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      formatDuration(Duration(seconds: message.mediaDuration!)),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioMessage(ChatMessageModel message) {
    final modernTheme = context.modernTheme;
    
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.play_circle_filled,
            color: modernTheme.primaryColor,
            size: 32,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress bar
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const LinearProgressIndicator(
                    value: 0.0, // Not playing
                    backgroundColor: Colors.transparent,
                  ),
                ),
                const SizedBox(height: 6),
                // Duration
                if (message.mediaDuration != null)
                  Text(
                    formatDuration(Duration(seconds: message.mediaDuration!)),
                    style: TextStyle(
                      fontSize: 12,
                      color: modernTheme.textSecondaryColor,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileMessage(ChatMessageModel message) {
    final modernTheme = context.modernTheme;
    
    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: modernTheme.primaryColor?.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.insert_drive_file,
              color: modernTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.mediaName ?? 'File',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: modernTheme.textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  message.mediaSize != null
                      ? formatFileSize(message.mediaSize!)
                      : '',
                  style: TextStyle(
                    fontSize: 12,
                    color: modernTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.download,
            color: modernTheme.primaryColor,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMessage(ChatMessageModel message) {
    final modernTheme = context.modernTheme;
    
    return Container(
      width: 200,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.map,
              size: 70,
              color: modernTheme.primaryColor?.withOpacity(0.3),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Text(
                message.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactMessage(ChatMessageModel message) {
    final modernTheme = context.modernTheme;
    
    final contactData = message.contactData;
    final contactName = contactData?['name'] as String? ?? 'Contact';
    final contactImage = contactData?['image'] as String? ?? '';
    
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          userImageWidget(
            imageUrl: contactImage,
            radius: 20,
            onTap: () {},
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contactName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: modernTheme.textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Contact',
                  style: TextStyle(
                    fontSize: 12,
                    color: modernTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.add_circle_outline,
            color: modernTheme.primaryColor,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsMenu(bool isSender) {
    final modernTheme = context.modernTheme;
    final options = [
      {
        'icon': Icons.reply,
        'label': 'Reply',
        'onTap': widget.onReplyTap,
      },
      {
        'icon': Icons.content_copy,
        'label': 'Copy',
        'onTap': () {
          if (widget.message.messageType == MessageEnum.text) {
            Clipboard.setData(ClipboardData(text: widget.message.message));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Message copied to clipboard')),
            );
          }
          setState(() {
            _showOptions = false;
          });
        },
      },
      {
        'icon': Icons.forward,
        'label': 'Forward',
        'onTap': () {
          // Implementation for forwarding
          setState(() {
            _showOptions = false;
          });
        },
      },
      if (isSender)
        {
          'icon': Icons.delete,
          'label': 'Delete',
          'onTap': () {
            _confirmDeleteMessage();
            setState(() {
              _showOptions = false;
            });
          },
        },
    ];

    return Container(
      margin: EdgeInsets.only(
        left: isSender ? 100 : 0,
        right: isSender ? 0 : 100,
        bottom: 8,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: options.map((option) {
          return InkWell(
            onTap: option['onTap'] as Function(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    option['icon'] as IconData,
                    color: modernTheme.textColor,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: modernTheme.textColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _confirmDeleteMessage() {
    final modernTheme = context.modernTheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text(
          'Are you sure you want to delete this message?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: TextStyle(color: modernTheme.textColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage();
            },
            child: const Text(
              'DELETE',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteMessage() {
    final message = widget.message;
    final interactionNotifier = ref.read(messageInteractionProvider.notifier);
    
    if (message.isMe) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Message'),
          content: const Text(
            'Delete for everyone or just for yourself?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Delete for me
                interactionNotifier.deleteMessageForMe(
                  messageId: message.messageId,
                );
              },
              child: const Text('DELETE FOR ME'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Delete for everyone
                interactionNotifier.deleteMessageForEveryone(
                  messageId: message.messageId,
                );
              },
              child: const Text(
                'DELETE FOR EVERYONE',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    } else {
      // Only delete for me
      interactionNotifier.deleteMessageForMe(
        messageId: message.messageId,
      );
    }
  }
}