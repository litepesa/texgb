// lib/features/chat/screens/chat_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
import 'package:textgb/features/chat/widgets/chat_input.dart';
import 'package:textgb/features/chat/widgets/message_bubble.dart';
import 'package:textgb/features/chat/widgets/reaction_picker.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Set message text if editing
    final chatState = ref.watch(chatProvider);
    if (chatState.valueOrNull?.editingMessage != null && 
        _messageController.text.isEmpty) {
      _messageController.text = chatState.valueOrNull!.editingMessage!.message;
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      ref.read(chatProvider.notifier).sendTextMessage(_messageController.text);
      _messageController.clear();
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

  // Handle message tap
  void _handleMessageTap(MessageModel message) {
    if (message.messageType == MessageEnum.image) {
      // Navigate to image viewer
      Navigator.pushNamed(
        context,
        '/mediaViewerScreen',
        arguments: {
          'message': message,
          'sender': message.senderUID == widget.contact.uid 
              ? widget.contact 
              : ref.read(currentUserProvider)!,
        },
      );
    } else if (message.messageType == MessageEnum.video) {
      // Navigate to video player
      Navigator.pushNamed(
        context,
        '/mediaViewerScreen',
        arguments: {
          'message': message,
          'sender': message.senderUID == widget.contact.uid 
              ? widget.contact 
              : ref.read(currentUserProvider)!,
        },
      );
    }
  }
  
  // Handle message long press to show options
  void _showMessageOptions(MessageModel message) {
    final chatNotifier = ref.read(chatProvider.notifier);
    final currentUser = ref.read(currentUserProvider);
    
    // Check if the message is from the current user
    final isFromMe = message.senderUID == currentUser?.uid;
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reply option
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  chatNotifier.setReplyingTo(message);
                },
              ),
              
              // React option
              ListTile(
                leading: const Icon(Icons.emoji_emotions),
                title: const Text('React'),
                onTap: () {
                  Navigator.pop(context);
                  _showReactionPicker(message);
                },
              ),
              
              // Edit option (only for text messages from current user)
              if (isFromMe && message.messageType == MessageEnum.text)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit'),
                  onTap: () {
                    Navigator.pop(context);
                    chatNotifier.setEditingMessage(message);
                    _messageController.text = message.message;
                    _messageController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _messageController.text.length),
                    );
                    FocusScope.of(context).requestFocus(FocusNode());
                  },
                ),
              
              // Copy option for text messages
              if (message.messageType == MessageEnum.text)
                ListTile(
                  leading: const Icon(Icons.content_copy),
                  title: const Text('Copy'),
                  onTap: () {
                    Navigator.pop(context);
                    // Copy to clipboard
                  },
                ),
              
              // Delete for me option
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete for me'),
                onTap: () {
                  Navigator.pop(context);
                  chatNotifier.deleteMessage(message.messageId);
                },
              ),
              
              // Delete for everyone option (only for messages from current user)
              if (isFromMe)
                ListTile(
                  leading: const Icon(Icons.delete_forever),
                  title: const Text('Delete for everyone'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteForEveryoneConfirmation(message);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
  
  // Show confirmation dialog for delete for everyone
  void _showDeleteForEveryoneConfirmation(MessageModel message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete for everyone?'),
        content: const Text(
          'This message will be deleted for everyone in this chat. This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(chatProvider.notifier).deleteMessageForEveryone(message.messageId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  // Show reaction picker
  void _showReactionPicker(MessageModel message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ReactionPicker(
        onReactionSelected: (emoji) {
          Navigator.pop(context);
          
          // Check if the user already has this reaction
          final currentUser = ref.read(currentUserProvider);
          if (currentUser == null) return;
          
          final hasReaction = message.reactions.containsKey(currentUser.uid);
          final hasSameReaction = hasReaction && 
              message.reactions[currentUser.uid]?['emoji'] == emoji;
          
          if (hasSameReaction) {
            // Remove reaction if it's the same
            ref.read(chatProvider.notifier).removeReaction(message.messageId);
          } else {
            // Add or update reaction
            ref.read(chatProvider.notifier).addReaction(message.messageId, emoji);
          }
        },
      ),
    );
  }
  
  // Handle swipe to reply
  void _handleSwipeToReply(MessageModel message) {
    ref.read(chatProvider.notifier).setReplyingTo(message);
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final chatTheme = context.chatTheme;

    // Watch messages stream for current chat
    final messagesStream = ref.watch(messageStreamProvider(widget.chatId));
    final chatState = ref.watch(chatProvider);
    
    // Check if we're editing a message
    final bool isEditing = chatState.valueOrNull?.editingMessage != null;

    return Scaffold(
      backgroundColor: chatTheme.chatBackgroundColor,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // Editing indicator
          if (isEditing)
            _buildEditingContainer(chatState.valueOrNull!.editingMessage!),
          
          // Reply UI if replying to a message
          if (!isEditing && chatState.valueOrNull?.replyingTo != null)
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
                    
                    // Mark message as delivered if it's received
                    final currentUser = ref.read(currentUserProvider);
                    if (currentUser != null && 
                        message.senderUID != currentUser.uid && 
                        !message.isDelivered) {
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
                          onSwipe: _handleSwipeToReply,
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
            isEditing: isEditing,
            onCancelEditing: isEditing 
                ? () {
                    ref.read(chatProvider.notifier).cancelEditing();
                    _messageController.clear();
                  }
                : null,
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
          Text(
            widget.contact.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
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

  Widget _buildEditingContainer(MessageModel editingMessage) {
    final modernTheme = context.modernTheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blue.withOpacity(0.1),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue,
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
                  'Editing message',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  editingMessage.message,
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
              ref.read(chatProvider.notifier).cancelEditing();
              _messageController.clear();
            },
          ),
        ],
      ),
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
}