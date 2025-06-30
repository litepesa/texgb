// lib/features/groups/screens/group_chat_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
import 'package:textgb/features/chat/widgets/chat_input.dart';
import 'package:textgb/features/chat/widgets/message_bubble.dart';
import 'package:textgb/features/chat/widgets/swipe_to_reply.dart';
import 'package:textgb/features/chat/widgets/attachment_picker.dart';
import 'package:textgb/features/chat/widgets/reaction_picker.dart';
import 'package:textgb/features/groups/models/group_model.dart';
import 'package:textgb/features/groups/providers/group_provider.dart';
import 'package:textgb/features/groups/repositories/group_repository.dart';
import 'package:textgb/features/groups/services/group_security_service.dart';
import 'package:textgb/features/groups/widgets/group_chat_app_bar.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class GroupChatScreen extends ConsumerStatefulWidget {
  final String groupId;
  final GroupModel group;

  const GroupChatScreen({
    Key? key,
    required this.groupId,
    required this.group,
  }) : super(key: key);

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> 
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Modern UI state
  bool _isAttachmentPickerVisible = false;
  bool _showScrollToBottom = false;
  bool _isRecording = false;
  
  // Permissions state
  bool _canSendMessages = false;
  bool _canViewMessages = false;
  bool _isLoading = true;
  String? _permissionError;
  late GroupSecurityService _securityService;

  // Animation controllers for modern UI
  late AnimationController _typingController;
  late Animation<double> _typingAnimation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    // Initialize security service using the public getters
    final repository = ref.read(groupRepositoryProvider);
    _securityService = GroupSecurityService(
      firestore: repository.firestore,
      auth: repository.auth,
    );
    
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
    
    // Add observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    
    // Listen to scroll events for modern scroll-to-bottom button
    _scrollController.addListener(_onScroll);
    
    // Initialize chat permissions and load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChatPermissions();
    });
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Set message text if editing
    final chatState = ref.watch(chatProvider);
    if (chatState.valueOrNull?.editingMessage != null && 
        _messageController.text.isEmpty) {
      _messageController.text = chatState.valueOrNull!.editingMessage!.message;
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (state == AppLifecycleState.resumed && _canViewMessages) {
      // When app is resumed, reset unread counter for current chat
      _resetUnreadCounter();
    }
  }

  /// Initialize chat permissions and validate access
  Future<void> _initializeChatPermissions() async {
    try {
      setState(() {
        _isLoading = true;
        _permissionError = null;
      });

      // Check if user can view messages
      final canView = await _securityService.canUserViewGroup(widget.groupId);
      if (!canView) {
        setState(() {
          _permissionError = 'You do not have permission to view this group';
          _isLoading = false;
        });
        return;
      }

      // Check if user can send messages
      final canSend = await _securityService.canUserSendMessages(widget.groupId);
      
      setState(() {
        _canViewMessages = canView;
        _canSendMessages = canSend;
        _isLoading = false;
      });

      if (_canViewMessages) {
        // Load group details and reset unread counter
        await ref.read(groupProvider.notifier).getGroupDetails(widget.groupId);
        await _resetUnreadCounter();
        
        // Open the chat in the chat provider
        await ref.read(chatProvider.notifier).openGroupChat(widget.groupId, []);
      }
    } catch (e) {
      setState(() {
        _permissionError = 'Error loading group: $e';
        _isLoading = false;
      });
    }
  }

  /// Reset unread counter for current user
  Future<void> _resetUnreadCounter() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null && _canViewMessages) {
      try {
        await ref.read(groupRepositoryProvider)
            .resetGroupUnreadCounter(widget.groupId, currentUser.uid);
      } catch (e) {
        debugPrint('Error resetting unread counter: $e');
      }
    }
  }

  /// Send message with permission validation and haptic feedback
  void _sendMessage() async {
    if (!_canSendMessages) {
      showSnackBar(context, 'You do not have permission to send messages in this group');
      return;
    }

    if (_messageController.text.trim().isNotEmpty) {
      try {
        HapticFeedback.lightImpact();
        // Use sendGroupMessage for group chats
        await ref.read(chatProvider.notifier).sendGroupMessage(
          message: _messageController.text,
          messageType: MessageEnum.text,
        );
        _messageController.clear();
        _scrollToBottom();
      } catch (e) {
        if (mounted) {
          showSnackBar(context, 'Failed to send message: $e');
        }
      }
    }
  }

  /// Scroll to bottom with animation
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Toggle modern attachment picker
  void _toggleAttachmentPicker() {
    if (!_canSendMessages) {
      showSnackBar(context, 'You do not have permission to send media in this group');
      return;
    }
    
    setState(() => _isAttachmentPickerVisible = !_isAttachmentPickerVisible);
  }

  /// Handle modern attachment selection
  void _handleAttachmentSelection(AttachmentType type) async {
    setState(() => _isAttachmentPickerVisible = false);
    
    if (!_canSendMessages) {
      showSnackBar(context, 'You do not have permission to send media in this group');
      return;
    }
    
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

  /// Pick and send image
  Future<void> _pickImage({required bool fromCamera}) async {
    try {
      final image = await pickImage(
        fromCamera: fromCamera,
        onFail: (error) => showSnackBar(context, error),
      );

      if (image != null) {
        await ref.read(chatProvider.notifier).sendGroupMediaMessage(
          file: image,
          messageType: MessageEnum.image,
        );
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to send image: $e');
      }
    }
  }

  /// Pick and send video
  Future<void> _pickVideo({required bool fromCamera}) async {
    try {
      final video = fromCamera 
          ? await pickVideoFromCamera(onFail: (error) => showSnackBar(context, error))
          : await pickVideo(onFail: (error) => showSnackBar(context, error));

      if (video != null) {
        await ref.read(chatProvider.notifier).sendGroupMediaMessage(
          file: video,
          messageType: MessageEnum.video,
        );
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to send video: $e');
      }
    }
  }

  /// Show coming soon message
  void _showComingSoon(String feature) {
    showSnackBar(context, '$feature feature coming soon');
  }

  /// Handle message tap with enhanced navigation
  void _handleMessageTap(MessageModel message) {
    if (!_canViewMessages) return;
    
    if (message.messageType == MessageEnum.image || message.messageType == MessageEnum.video) {
      Navigator.pushNamed(
        context,
        '/mediaViewerScreen',
        arguments: {
          'message': message,
          'sender': _getSenderFromMessage(message),
        },
      );
    }
  }

  /// Get sender user model from message
  UserModel _getSenderFromMessage(MessageModel message) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null && message.senderUID == currentUser.uid) {
      return currentUser;
    }

    final groupState = ref.read(groupProvider);
    final groupMembers = groupState.valueOrNull?.currentGroupMembers ?? [];
    
    return groupMembers.firstWhere(
      (member) => member.uid == message.senderUID,
      orElse: () => UserModel(
        uid: message.senderUID,
        name: message.senderName,
        phoneNumber: '',
        image: message.senderImage,
        aboutMe: '',
        lastSeen: '',
        token: '',
        createdAt: '',
        contactsUIDs: [],
        blockedUIDs: [],
      ),
    );
  }
  
  /// Show modern message options with permission checks
  void _showMessageOptions(MessageModel message) {
    if (!_canViewMessages) return;
    
    final chatNotifier = ref.read(chatProvider.notifier);
    final currentUser = ref.read(currentUserProvider);
    final modernTheme = context.modernTheme;
    
    final isFromMe = currentUser != null && message.senderUID == currentUser.uid;
    
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
              if (_canSendMessages)
                _buildOptionTile(
                  icon: Icons.reply_rounded,
                  label: 'Reply',
                  onTap: () {
                    Navigator.pop(context);
                    chatNotifier.setReplyingTo(message);
                  },
                ),
              
              // React option
              if (_canSendMessages)
                _buildOptionTile(
                  icon: Icons.emoji_emotions_rounded,
                  label: 'Add Reaction',
                  onTap: () {
                    Navigator.pop(context);
                    _showReactionPicker(message);
                  },
                ),
              
              // Edit option
              if (isFromMe && message.messageType == MessageEnum.text && _canSendMessages)
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
              
              // Copy option
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
              
              // Delete for me
              _buildOptionTile(
                icon: Icons.delete_outline_rounded,
                label: 'Delete for me',
                onTap: () {
                  Navigator.pop(context);
                  chatNotifier.deleteMessage(message.messageId);
                },
              ),
              
              // Delete for everyone
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
  
  /// Show confirmation dialog for delete for everyone
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
          'This message will be deleted for everyone in this group. This action cannot be undone.',
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
  
  /// Show modern reaction picker
  void _showReactionPicker(MessageModel message) {
    if (!_canSendMessages) {
      showSnackBar(context, 'You do not have permission to react in this group');
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => ReactionPicker(
        onReactionSelected: (emoji) {
          Navigator.pop(context);
          
          final currentUser = ref.read(currentUserProvider);
          if (currentUser == null) return;
          
          final hasReaction = message.reactions.containsKey(currentUser.uid);
          final hasSameReaction = hasReaction && 
              message.reactions[currentUser.uid]?['emoji'] == emoji;
          
          if (hasSameReaction) {
            ref.read(chatProvider.notifier).removeReaction(message.messageId);
          } else {
            ref.read(chatProvider.notifier).addReaction(message.messageId, emoji);
          }
        },
      ),
    );
  }
  
  /// Handle modern swipe to reply
  void _handleSwipeToReply(MessageModel message) {
    if (!_canSendMessages) {
      showSnackBar(context, 'You do not have permission to reply in this group');
      return;
    }
    
    ref.read(chatProvider.notifier).setReplyingTo(message);
    HapticFeedback.lightImpact();
  }

  /// Voice recording methods
  void _startRecording() {
    if (!_canSendMessages) {
      showSnackBar(context, 'You do not have permission to send voice messages in this group');
      return;
    }
    
    setState(() => _isRecording = true);
    HapticFeedback.mediumImpact();
    // TODO: Implement voice recording
  }

  void _stopRecording() {
    setState(() => _isRecording = false);
    HapticFeedback.lightImpact();
    // TODO: Implement voice recording
  }

  /// Build enhanced group app bar
  PreferredSizeWidget _buildGroupAppBar(BuildContext context, GroupModel group) {
    return GroupChatAppBar(
      group: group,
      onBack: () => Navigator.pop(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final modernTheme = context.modernTheme;
    final chatTheme = context.chatTheme;
    
    // Show loading screen
    if (_isLoading) {
      return Scaffold(
        backgroundColor: chatTheme.chatBackgroundColor,
        appBar: _buildGroupAppBar(context, widget.group),
        body: _buildLoadingState(),
      );
    }

    // Show permission error
    if (_permissionError != null) {
      return Scaffold(
        backgroundColor: chatTheme.chatBackgroundColor,
        appBar: _buildGroupAppBar(context, widget.group),
        body: _buildPermissionErrorState(),
      );
    }

    // Watch group details
    final groupState = ref.watch(groupProvider);
    final group = groupState.valueOrNull?.currentGroup ?? widget.group;
    final groupMembers = groupState.valueOrNull?.currentGroupMembers ?? [];
    
    // Watch messages stream for current group
    final messagesStream = ref.watch(messageStreamProvider(widget.groupId));
    final chatState = ref.watch(chatProvider);

    return Scaffold(
      backgroundColor: chatTheme.chatBackgroundColor,
      appBar: _buildGroupAppBar(context, group),
      body: Stack(
        children: [
          // Chat background with subtle pattern
          _buildChatBackground(),
          
          // Main content
          Column(
            children: [
              // Permission warning banner
              if (_canViewMessages && !_canSendMessages)
                _buildPermissionBanner(),

              // Messages list
              Expanded(
                child: messagesStream.when(
                  data: (messages) => _buildMessagesList(messages, groupMembers, chatState),
                  loading: () => _buildMessagesLoadingState(),
                  error: (error, stack) => _buildMessagesErrorState(error),
                ),
              ),

              // Chat input (only show if user can send messages)
              if (_canSendMessages)
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
              bottom: _canSendMessages ? 100 : 20,
              right: 16,
              child: _buildScrollToBottomButton(modernTheme),
            ),

          // Modern attachment picker overlay
          if (_isAttachmentPickerVisible)
            AttachmentPicker(
              onAttachmentSelected: _handleAttachmentSelection,
              onClose: () => setState(() => _isAttachmentPickerVisible = false),
            ),
        ],
      ),
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
            'Loading group...',
            style: TextStyle(color: modernTheme.textSecondaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionErrorState() {
    final modernTheme = context.modernTheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
                Icons.lock_outline,
                size: 48,
                color: modernTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Access Denied',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: modernTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _permissionError!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.amber.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: Colors.amber[700],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You can view messages but cannot send messages in this group',
              style: TextStyle(
                fontSize: 14,
                color: Colors.amber[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(List<MessageModel> messages, List<UserModel> groupMembers, AsyncValue<ChatState> chatState) {
    if (messages.isEmpty) {
      return _buildEmptyMessagesState();
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
        
        // Get sender info for display
        final messageSender = groupMembers.firstWhere(
          (member) => member.uid == message.senderUID,
          orElse: () => UserModel(
            uid: message.senderUID,
            name: message.senderName,
            phoneNumber: '',
            image: message.senderImage,
            aboutMe: '',
            lastSeen: '',
            token: '',
            createdAt: '',
            contactsUIDs: [],
            blockedUIDs: [],
          ),
        );
        
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
            
            // Message with modern swipe-to-reply
            SwipeToReply(
              message: message,
              onReply: _handleSwipeToReply,
              isMyMessage: currentUser?.uid == message.senderUID,
              child: MessageBubble(
                message: message,
                previousMessage: previousMessage,
                nextMessage: nextMessage,
                contact: messageSender,
                onTap: () => _handleMessageTap(message),
                onLongPress: () => _showMessageOptions(message),
                onSwipeToReply: _canSendMessages ? _handleSwipeToReply : null,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyMessagesState() {
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
              Icons.group_outlined,
              size: 48,
              color: modernTheme.textSecondaryColor?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _canSendMessages 
                ? 'Start the group conversation'
                : 'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: modernTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _canSendMessages 
                ? 'Send the first message to ${widget.group.name}'
                : 'Waiting for messages in ${widget.group.name}',
            style: TextStyle(
              fontSize: 14,
              color: modernTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesLoadingState() {
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

  Widget _buildMessagesErrorState(dynamic error) {
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
            onPressed: () => _initializeChatPermissions(),
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
}