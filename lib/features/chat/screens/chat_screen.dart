// lib/features/chat/screens/chat_screen.dart
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
import 'package:textgb/features/chat/widgets/message_bubble.dart';
import 'package:textgb/features/chat/widgets/chat_input.dart';
import 'package:textgb/features/chat/widgets/attachment_picker.dart';
import 'package:textgb/features/chat/widgets/swipe_to_reply.dart';
import 'package:textgb/features/groups/models/group_model.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final UserModel contact;
  final bool isGroup;
  final GroupModel? group;

  const ChatScreen({
    Key? key,
    required this.chatId,
    required this.contact,
    this.isGroup = false,
    this.group,
  }) : super(key: key);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late AnimationController _typingController;
  late Animation<double> _typingAnimation;
  
  bool _isAttachmentPickerVisible = false;
  bool _isRecording = false;
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    
    // Add observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize typing animation
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _typingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _typingController,
      curve: Curves.easeInOut,
    ));
    
    // Initialize chat when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isGroup && widget.group != null) {
        ref.read(chatProvider.notifier).openGroupChat(
          widget.chatId, 
          [], // TODO: Get group members
        );
      } else {
        ref.read(chatProvider.notifier).openChat(widget.chatId, widget.contact);
      }
    });
    
    // Listen to scroll events
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > 200;
    if (shouldShow != _showScrollToBottom) {
      setState(() => _showScrollToBottom = shouldShow);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reset unread counter when app is resumed
      if (widget.isGroup && widget.group != null) {
        ref.read(chatProvider.notifier).openGroupChat(
          widget.chatId, 
          [], // TODO: Get group members
        );
      } else {
        ref.read(chatProvider.notifier).openChat(widget.chatId, widget.contact);
      }
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      HapticFeedback.lightImpact();
      ref.read(chatProvider.notifier).sendTextMessage(_messageController.text);
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _toggleAttachmentPicker() {
    setState(() => _isAttachmentPickerVisible = !_isAttachmentPickerVisible);
  }

  void _handleAttachmentSelection(AttachmentType type) async {
    setState(() => _isAttachmentPickerVisible = false);
    
    switch (type) {
      case AttachmentType.gallery:
        await _pickImage(fromCamera: false);
        break;
      case AttachmentType.camera:
        await _pickImage(fromCamera: true);
        break;
      case AttachmentType.video:
        await _pickVideo(fromCamera: false);
        break;
      case AttachmentType.document:
        _showComingSoon('Document sharing');
        break;
      case AttachmentType.location:
        _showComingSoon('Location sharing');
        break;
      case AttachmentType.contact:
        _showComingSoon('Contact sharing');
        break;
    }
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
  }

  void _showComingSoon(String feature) {
    showSnackBar(context, '$feature feature coming soon');
  }

  void _handleSwipeToReply(MessageModel message) {
    ref.read(chatProvider.notifier).setReplyingTo(message);
    HapticFeedback.lightImpact();
  }

  void _startRecording() {
    setState(() => _isRecording = true);
    HapticFeedback.mediumImpact();
    // TODO: Implement voice recording
  }

  void _stopRecording() {
    setState(() => _isRecording = false);
    HapticFeedback.lightImpact();
    // TODO: Implement voice recording
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final chatTheme = context.chatTheme;
    final messagesStream = ref.watch(messageStreamProvider(widget.chatId));
    final chatState = ref.watch(chatProvider);

    return Scaffold(
      backgroundColor: chatTheme.chatBackgroundColor,
      appBar: _buildModernAppBar(),
      body: Stack(
        children: [
          // Chat background with subtle pattern
          _buildChatBackground(),
          
          // Main chat content
          Column(
            children: [
              // Messages list
              Expanded(
                child: messagesStream.when(
                  data: (messages) => _buildMessagesList(messages, chatState),
                  loading: () => _buildLoadingState(),
                  error: (error, stack) => _buildErrorState(error),
                ),
              ),

              // Chat input
              ChatInput(
                controller: _messageController,
                onSend: _sendMessage,
                onAttachmentTap: _toggleAttachmentPicker,
                isEditing: chatState.valueOrNull?.editingMessage != null,
                editingMessage: chatState.valueOrNull?.editingMessage,
                replyingTo: chatState.valueOrNull?.replyingTo,
                onCancelEditing: () {
                  ref.read(chatProvider.notifier).cancelEditing();
                  _messageController.clear();
                },
                onCancelReply: () {
                  ref.read(chatProvider.notifier).cancelReply();
                },
                isRecording: _isRecording,
                onStartRecording: _startRecording,
                onStopRecording: _stopRecording,
              ),
            ],
          ),

          // Scroll to bottom button
          if (_showScrollToBottom)
            Positioned(
              bottom: 100,
              right: 16,
              child: _buildScrollToBottomButton(modernTheme),
            ),

          // Attachment picker overlay
          if (_isAttachmentPickerVisible)
            AttachmentPicker(
              onAttachmentSelected: _handleAttachmentSelection,
              onClose: () => setState(() => _isAttachmentPickerVisible = false),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    final modernTheme = context.modernTheme;
    
    return AppBar(
      elevation: 0,
      backgroundColor: modernTheme.appBarColor,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: modernTheme.backgroundColor == modernTheme.appBarColor 
            ? Brightness.light 
            : Brightness.dark,
      ),
      title: Row(
        children: [
          // Contact avatar with online indicator
          Stack(
            children: [
              CircleAvatar(
                backgroundImage: widget.contact.image.isNotEmpty
                    ? NetworkImage(widget.contact.image)
                    : const AssetImage('assets/images/user_icon.png') as ImageProvider,
                radius: 20,
              ),
              // Online indicator (example)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: modernTheme.appBarColor ?? Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          
          // Contact info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contact.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: modernTheme.textColor,
                  ),
                ),
                // Typing indicator or last seen
                AnimatedBuilder(
                  animation: _typingAnimation,
                  builder: (context, child) {
                    return Text(
                      'last seen recently', // TODO: Implement real last seen
                      style: TextStyle(
                        fontSize: 12,
                        color: modernTheme.textSecondaryColor,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      leading: AppBarBackButton(
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // Video call button
        IconButton(
          icon: Icon(
            Icons.videocam_rounded,
            color: modernTheme.textColor,
          ),
          onPressed: () => _showComingSoon('Video call'),
          tooltip: 'Video call',
        ),
        
        // Audio call button
        IconButton(
          icon: Icon(
            Icons.call_rounded,
            color: modernTheme.textColor,
          ),
          onPressed: () => _showComingSoon('Audio call'),
          tooltip: 'Audio call',
        ),
        
        // More options
        IconButton(
          icon: Icon(
            Icons.more_vert_rounded,
            color: modernTheme.textColor,
          ),
          onPressed: () => _showComingSoon('More options'),
          tooltip: 'More options',
        ),
      ],
    );
  }

  Widget _buildChatBackground() {
    final chatTheme = context.chatTheme;
    
    return Container(
      decoration: BoxDecoration(
        color: chatTheme.chatBackgroundColor,
        // Optional: Add subtle pattern or gradient
        image: const DecorationImage(
          image: AssetImage('assets/images/chat_background_pattern.png'),
          fit: BoxFit.cover,
          opacity: 0.03,
        ),
      ),
    );
  }

  Widget _buildMessagesList(List<MessageModel> messages, AsyncValue<ChatState> chatState) {
    if (messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final previousMessage = index < messages.length - 1 ? messages[index + 1] : null;
        final nextMessage = index > 0 ? messages[index - 1] : null;
        
        // Mark message as delivered if needed
        final currentUser = ref.read(currentUserProvider);
        if (currentUser != null && 
            message.senderUID != currentUser.uid && 
            message.messageStatus == MessageStatus.sent) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(chatProvider.notifier).markMessageAsDelivered(message.messageId);
          });
        }

        // Check if we should show date header
        final showDateHeader = _shouldShowDateHeader(messages, index);

        return Column(
          children: [
            // Date header
            if (showDateHeader) 
              _buildDateHeader(message),
            
            // Message with swipe-to-reply
            SwipeToReply(
              message: message,
              onReply: _handleSwipeToReply,
              isMyMessage: currentUser?.uid == message.senderUID,
              child: MessageBubble(
                message: message,
                previousMessage: previousMessage,
                nextMessage: nextMessage,
                contact: widget.contact,
                onTap: () => _handleMessageTap(message),
                onLongPress: () => _showMessageOptions(message),
                onSwipeToReply: _handleSwipeToReply,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final modernTheme = context.modernTheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: modernTheme.surfaceColor?.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: modernTheme.textSecondaryColor?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Start your conversation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: modernTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to ${widget.contact.name}',
            style: TextStyle(
              fontSize: 14,
              color: modernTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    final modernTheme = context.modernTheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: modernTheme.primaryColor,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading messages...',
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(dynamic error) {
    final modernTheme = context.modernTheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: Colors.red.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load messages',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: modernTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(
              fontSize: 14,
              color: modernTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Retry loading
              ref.refresh(messageStreamProvider(widget.chatId));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: modernTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollToBottomButton(ModernThemeExtension modernTheme) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: _scrollToBottom,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                modernTheme.primaryColor ?? Colors.blue,
                (modernTheme.primaryColor ?? Colors.blue).withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildDateHeader(MessageModel message) {
    final modernTheme = context.modernTheme;
    final dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(message.timeSent));
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
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: modernTheme.surfaceVariantColor?.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            dateText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: modernTheme.textSecondaryColor,
            ),
          ),
        ),
      ),
    );
  }

  bool _shouldShowDateHeader(List<MessageModel> messages, int index) {
    if (index == messages.length - 1) return true;
    
    final currentDate = DateTime.fromMillisecondsSinceEpoch(int.parse(messages[index].timeSent));
    final previousDate = DateTime.fromMillisecondsSinceEpoch(int.parse(messages[index + 1].timeSent));
    
    return currentDate.year != previousDate.year ||
           currentDate.month != previousDate.month ||
           currentDate.day != previousDate.day;
  }

  void _handleMessageTap(MessageModel message) {
    if (message.messageType == MessageEnum.image || message.messageType == MessageEnum.video) {
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

  void _showMessageOptions(MessageModel message) {
    final chatNotifier = ref.read(chatProvider.notifier);
    final currentUser = ref.read(currentUserProvider);
    final modernTheme = context.modernTheme;
    
    final isFromMe = message.senderUID == currentUser?.uid;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: modernTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: modernTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              
              // Reply option
              _buildOptionTile(
                icon: Icons.reply_rounded,
                label: 'Reply',
                onTap: () {
                  Navigator.pop(context);
                  chatNotifier.setReplyingTo(message);
                },
              ),
              
              // React option
              _buildOptionTile(
                icon: Icons.emoji_emotions_rounded,
                label: 'Add Reaction',
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoon('Reactions');
                },
              ),
              
              // Edit option (only for text messages from current user)
              if (isFromMe && message.messageType == MessageEnum.text)
                _buildOptionTile(
                  icon: Icons.edit_rounded,
                  label: 'Edit',
                  onTap: () {
                    Navigator.pop(context);
                    chatNotifier.setEditingMessage(message);
                    _messageController.text = message.message;
                    _messageController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _messageController.text.length),
                    );
                  },
                ),
              
              // Copy option for text messages
              if (message.messageType == MessageEnum.text)
                _buildOptionTile(
                  icon: Icons.content_copy_rounded,
                  label: 'Copy',
                  onTap: () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(text: message.message));
                    showSnackBar(context, 'Message copied');
                  },
                ),
              
              // Forward option
              _buildOptionTile(
                icon: Icons.share_rounded,
                label: 'Forward',
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoon('Forward message');
                },
              ),
              
              // Delete for me option
              _buildOptionTile(
                icon: Icons.delete_outline_rounded,
                label: 'Delete for me',
                onTap: () {
                  Navigator.pop(context);
                  chatNotifier.deleteMessage(message.messageId);
                },
              ),
              
              // Delete for everyone option (only for messages from current user)
              if (isFromMe)
                _buildOptionTile(
                  icon: Icons.delete_forever_rounded,
                  label: 'Delete for everyone',
                  textColor: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteForEveryoneConfirmation(message);
                  },
                ),
              
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    final modernTheme = context.modernTheme;
    
    return ListTile(
      leading: Icon(
        icon,
        color: textColor ?? modernTheme.textColor,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: textColor ?? modernTheme.textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showDeleteForEveryoneConfirmation(MessageModel message) {
    final modernTheme = context.modernTheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: modernTheme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete for everyone?',
          style: TextStyle(color: modernTheme.textColor),
        ),
        content: Text(
          'This message will be deleted for everyone in this chat. This action cannot be undone.',
          style: TextStyle(color: modernTheme.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: modernTheme.textSecondaryColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(chatProvider.notifier).deleteMessageForEveryone(message.messageId);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}