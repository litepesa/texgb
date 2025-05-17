import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
import 'package:textgb/features/chat/widgets/chat_input.dart';
import 'package:textgb/features/chat/widgets/message_bubble.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final UserModel contact;

  const ChatScreen({
    Key? key,
    required this.chatId,
    required this.contact,
  }) : super(key: key);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAttachmentVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).openChat(widget.chatId, widget.contact);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      ref.read(chatProvider.notifier).sendTextMessage(_messageController.text);
      _messageController.clear();
      
      // Add haptic feedback when sending message
      HapticFeedback.lightImpact();
      
      // Scroll to bottom after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _toggleAttachmentMenu() {
    setState(() {
      _isAttachmentVisible = !_isAttachmentVisible;
    });
  }

  Future<void> _pickImage({required bool fromCamera}) async {
    final image = await pickImage(
      fromCamera: fromCamera,
      onFail: (error) => showSnackBar(context, error),
    );

    if (image != null) {
      ref.read(chatProvider.notifier).sendMediaMessage(
        file: image,
        messageType: MessageEnum.image,
      );
    }
    
    setState(() {
      _isAttachmentVisible = false;
    });
  }

  Future<void> _pickVideo({required bool fromCamera}) async {
    final video = fromCamera 
        ? await pickVideoFromCamera(onFail: (error) => showSnackBar(context, error))
        : await pickVideo(onFail: (error) => showSnackBar(context, error));

    if (video != null) {
      ref.read(chatProvider.notifier).sendMediaMessage(
        file: video,
        messageType: MessageEnum.video,
      );
    }
    
    setState(() {
      _isAttachmentVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final chatTheme = context.chatTheme;

    // Watch messages stream for current chat
    final messagesStream = ref.watch(messageStreamProvider(widget.chatId));
    final chatState = ref.watch(chatProvider);

    return Scaffold(
      backgroundColor: chatTheme.chatBackgroundColor,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // Reply UI if replying to a message
          if (chatState.valueOrNull?.replyingTo != null)
            _buildReplyContainer(chatState.valueOrNull!.replyingTo!),

          // Messages list
          Expanded(
            child: messagesStream.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Send a message to start chatting',
                      style: TextStyle(
                        color: modernTheme.textSecondaryColor,
                      ),
                    ),
                  );
                }
                
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  padding: const EdgeInsets.only(bottom: 8),
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final currentUser = ref.read(currentUserProvider);
                    
                    // Mark message as delivered if it's received and not yet delivered
                    if (currentUser != null && 
                        message.senderUID != currentUser.uid && 
                        !message.deliveredTo.contains(currentUser.uid)) {
                      ref.read(chatProvider.notifier).markMessageAsDelivered(message.messageId);
                    }
                    
                    // Add date header if needed
                    final showDateHeader = _shouldShowDateHeader(messages, index);
                    
                    return Column(
                      children: [
                        if (showDateHeader) _buildDateHeader(message),
                        MessageBubble(
                          message: message,
                          contact: widget.contact,
                          onTap: () => _handleMessageTap(message),
                          onLongPress: () => _showMessageOptions(message),
                          onSwipe: (messageId) {
                            // Handle swipe to reply
                            ref.read(chatProvider.notifier).setReplyingTo(message);
                            // Add haptic feedback for swipe to reply
                            HapticFeedback.lightImpact();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Text('Error loading messages: $error'),
              ),
            ),
          ),

          // Attachment menu
          if (_isAttachmentVisible) _buildAttachmentMenu(),

          // Chat input
          ChatInput(
            controller: _messageController,
            onSend: _sendMessage,
            onAttachmentTap: _toggleAttachmentMenu,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          CircleAvatar(
            backgroundImage: widget.contact.image.isNotEmpty
                ? NetworkImage(widget.contact.image)
                : const AssetImage('assets/images/user_icon.png') as ImageProvider,
            radius: 20,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.contact.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // No longer showing online/offline status
              const SizedBox(height: 2),
            ],
          ),
        ],
      ),
      leading: AppBarBackButton(
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam),
          onPressed: () {
            // TODO: Implement video call
            showSnackBar(context, 'Video call feature coming soon');
          },
        ),
        IconButton(
          icon: const Icon(Icons.call),
          onPressed: () {
            // TODO: Implement audio call
            showSnackBar(context, 'Audio call feature coming soon');
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            // TODO: Show more options
            showSnackBar(context, 'More options coming soon');
          },
        ),
      ],
    );
  }

  Widget _buildReplyContainer(MessageModel replyMessage) {
    final modernTheme = context.modernTheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: modernTheme.surfaceColor,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: modernTheme.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to ${replyMessage.senderUID == widget.contact.uid ? widget.contact.name : 'yourself'}',
                  style: TextStyle(
                    color: modernTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  replyMessage.messageType == MessageEnum.text 
                      ? replyMessage.message 
                      : '${replyMessage.messageType.displayName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: modernTheme.textSecondaryColor,
              size: 20,
            ),
            onPressed: () {
              ref.read(chatProvider.notifier).cancelReply();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentMenu() {
    final modernTheme = context.modernTheme;
    
    return Container(
      color: modernTheme.surfaceColor,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildAttachmentOption(
            icon: Icons.photo,
            label: 'Gallery',
            onTap: () => _pickImage(fromCamera: false),
            color: Colors.purple,
          ),
          _buildAttachmentOption(
            icon: Icons.camera_alt,
            label: 'Camera',
            onTap: () => _pickImage(fromCamera: true),
            color: Colors.red,
          ),
          _buildAttachmentOption(
            icon: Icons.videocam,
            label: 'Video',
            onTap: () => _pickVideo(fromCamera: false),
            color: Colors.blue,
          ),
          _buildAttachmentOption(
            icon: Icons.insert_drive_file,
            label: 'Document',
            onTap: () {
              // TODO: Implement document picking
              showSnackBar(context, 'Document sharing coming soon');
              setState(() {
                _isAttachmentVisible = false;
              });
            },
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: color,
            child: Icon(
              icon,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: context.modernTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(MessageModel message) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(
      int.parse(message.timeSent),
    );
    final today = DateTime.now();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    
    String dateText;
    if (dateTime.year == today.year && 
        dateTime.month == today.month && 
        dateTime.day == today.day) {
      dateText = 'Today';
    } else if (dateTime.year == yesterday.year && 
               dateTime.month == yesterday.month && 
               dateTime.day == yesterday.day) {
      dateText = 'Yesterday';
    } else {
      dateText = DateFormat('MMMM dd, yyyy').format(dateTime);
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: context.modernTheme.surfaceColor?.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        dateText,
        style: TextStyle(
          fontSize: 12,
          color: context.modernTheme.textSecondaryColor,
        ),
      ),
    );
  }

  bool _shouldShowDateHeader(List<MessageModel> messages, int index) {
    if (index == messages.length - 1) return true;
    
    final currentDate = DateTime.fromMillisecondsSinceEpoch(
      int.parse(messages[index].timeSent),
    );
    final previousDate = DateTime.fromMillisecondsSinceEpoch(
      int.parse(messages[index + 1].timeSent),
    );
    
    return currentDate.year != previousDate.year ||
           currentDate.month != previousDate.month ||
           currentDate.day != previousDate.day;
  }

  void _handleMessageTap(MessageModel message) {
    // Handle different message types
    if (message.messageType == MessageEnum.image) {
      // TODO: Show full image viewer
      Navigator.pushNamed(context, '/mediaViewScreen', arguments: {
        'message': message,
        'contact': widget.contact,
      });
    } else if (message.messageType == MessageEnum.video) {
      // TODO: Show video player
      Navigator.pushNamed(context, '/mediaViewScreen', arguments: {
        'message': message,
        'contact': widget.contact,
      });
    }
  }

  void _showMessageOptions(MessageModel message) {
    final chatNotifier = ref.read(chatProvider.notifier);
    final currentUser = ref.read(currentUserProvider);
    
    if (currentUser == null) return;
    
    // Add haptic feedback
    HapticFeedback.mediumImpact();
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reactions section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    '❤️', '👍', '👎', '😂', '😮', '😢'
                  ].map((emoji) => GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      chatNotifier.addReaction(message.messageId, emoji);
                      // Add haptic feedback for reaction
                      HapticFeedback.lightImpact();
                    },
                    child: Text(emoji, style: const TextStyle(fontSize: 30)),
                  )).toList(),
                ),
              ),
              
              const Divider(),
              
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  chatNotifier.setReplyingTo(message);
                },
              ),
              
              // Only show edit option for user's own text messages
              if (message.senderUID == currentUser.uid && 
                  message.messageType == MessageEnum.text)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDialog(context, message);
                  },
                ),
              
              // Copy option for text messages
              if (message.messageType == MessageEnum.text)
                ListTile(
                  leading: const Icon(Icons.content_copy),
                  title: const Text('Copy'),
                  onTap: () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(text: message.message));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message copied to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete for me'),
                onTap: () {
                  Navigator.pop(context);
                  chatNotifier.deleteMessage(message.messageId);
                },
              ),
              
              // Only show delete for everyone for user's own messages
              if (message.senderUID == currentUser.uid)
                ListTile(
                  leading: const Icon(Icons.delete_forever),
                  title: const Text('Delete for everyone'),
                  onTap: () {
                    Navigator.pop(context);
                    chatNotifier.deleteMessageForEveryone(message.messageId);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
  
  void _showEditDialog(BuildContext context, MessageModel message) {
    final chatNotifier = ref.read(chatProvider.notifier);
    final textController = TextEditingController(text: message.message);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Message'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Edit your message',
            ),
            maxLines: 5,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (textController.text.trim().isNotEmpty) {
                  chatNotifier.editMessage(
                    message.messageId,
                    textController.text.trim(),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}