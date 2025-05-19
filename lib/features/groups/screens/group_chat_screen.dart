// lib/features/groups/screens/group_chat_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
import 'package:textgb/features/chat/widgets/chat_input.dart';
import 'package:textgb/features/chat/widgets/message_bubble.dart';
import 'package:textgb/features/chat/widgets/reaction_picker.dart';
import 'package:textgb/features/groups/models/group_model.dart';
import 'package:textgb/features/groups/providers/group_provider.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

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

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAttachmentVisible = false;

  @override
  void initState() {
    super.initState();
    
    // Add observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize group chat when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(groupProvider.notifier).getGroupDetails(widget.groupId);
      ref.read(chatProvider.notifier).openGroupChat(widget.groupId, []);
    });
  }

  @override
  void dispose() {
    // This ensures we reset the unread counter when leaving the chat
    WidgetsBinding.instance.removeObserver(this);
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
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (state == AppLifecycleState.resumed) {
      // When app is resumed, reset unread counter for current chat
      ref.read(chatProvider.notifier).openGroupChat(widget.groupId, []);
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
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;
    
    if (message.messageType == MessageEnum.image || message.messageType == MessageEnum.video) {
      // Navigate to media viewer
      Navigator.pushNamed(
        context,
        '/mediaViewerScreen',
        arguments: {
          'message': message,
          'sender': message.senderUID == currentUser.uid
              ? currentUser
              : UserModel(
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
        },
      );
    }
  }
  
  // Handle message long press to show options
  void _showMessageOptions(MessageModel message) {
    final chatNotifier = ref.read(chatProvider.notifier);
    final currentUser = ref.read(currentUserProvider);
    
    // Check if the message is from the current user
    final isFromMe = currentUser != null && message.senderUID == currentUser.uid;
    
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
          'This message will be deleted for everyone in this group. This action cannot be undone.'
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
    
    // Watch group details
    final groupState = ref.watch(groupProvider);
    final group = groupState.valueOrNull?.currentGroup ?? widget.group;
    final groupMembers = groupState.valueOrNull?.currentGroupMembers ?? [];
    
    // Watch messages stream for current group
    final messagesStream = ref.watch(messageStreamProvider(widget.groupId));
    final chatState = ref.watch(chatProvider);
    
    // Check if we're editing a message
    final bool isEditing = chatState.valueOrNull?.editingMessage != null;

    return Scaffold(
      backgroundColor: chatTheme.chatBackgroundColor,
      appBar: _buildGroupAppBar(context, group),
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
                      'Send a message to start the group chat',
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
                    
                    // Mark message as delivered if it's received and not already delivered
                    final currentUser = ref.read(currentUserProvider);
                    if (currentUser != null && 
                        message.senderUID != currentUser.uid && 
                        message.messageStatus == MessageStatus.sent) {
                      ref.read(chatProvider.notifier).markMessageAsDelivered(message.messageId);
                    }
                    
                    // Add date header if needed
                    final showDateHeader = _shouldShowDateHeader(messages, index);
                    
                    return Column(
                      children: [
                        if (showDateHeader) _buildDateHeader(message),
                        MessageBubble(
                          message: message,
                          contact: messageSender,
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

  PreferredSizeWidget _buildGroupAppBar(BuildContext context, GroupModel group) {
    final modernTheme = context.modernTheme;
    final isAdmin = ref.read(groupProvider.notifier).isCurrentUserAdmin(group.groupId);
    
    return AppBar(
      elevation: 0,
      backgroundColor: modernTheme.backgroundColor,
      leading: AppBarBackButton(onPressed: () => Navigator.pop(context)),
      title: GestureDetector(
        onTap: () {
          // Navigate to group info screen when tapping on title
          Navigator.pushNamed(
            context,
            Constants.groupInformationScreen,
            arguments: group,
          );
        },
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: group.groupImage.isNotEmpty
                  ? NetworkImage(group.groupImage)
                  : null,
              backgroundColor: modernTheme.primaryColor?.withOpacity(0.2),
              radius: 18,
              child: group.groupImage.isEmpty
                  ? Icon(
                      Icons.group,
                      color: modernTheme.primaryColor,
                      size: 18,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.groupName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${group.membersUIDs.length} members',
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
      ),
      actions: [
        // Video call button
        IconButton(
          icon: const Icon(Icons.videocam),
          onPressed: () {
            showSnackBar(context, 'Group video call feature coming soon');
          },
        ),
        // Audio call button
        IconButton(
          icon: const Icon(Icons.call),
          onPressed: () {
            showSnackBar(context, 'Group audio call feature coming soon');
          },
        ),
        // Group settings button
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Group Info'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(
                          context,
                          Constants.groupInformationScreen,
                          arguments: group,
                        );
                      },
                    ),
                    if (isAdmin)
                      ListTile(
                        leading: const Icon(Icons.settings),
                        title: const Text('Group Settings'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            Constants.groupSettingsScreen,
                            arguments: group,
                          );
                        },
                      ),
                    if (group.awaitingApprovalUIDs.isNotEmpty && isAdmin)
                      ListTile(
                        leading: const Icon(Icons.person_add),
                        title: Text(
                          'Pending Requests (${group.awaitingApprovalUIDs.length})',
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            Constants.pendingRequestsScreen,
                            arguments: group,
                          );
                        },
                      ),
                    ListTile(
                      leading: const Icon(Icons.search),
                      title: const Text('Search Messages'),
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Implement search
                        showSnackBar(context, 'Message search coming soon');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.exit_to_app, color: Colors.red),
                      title: const Text('Leave Group', style: TextStyle(color: Colors.red)),
                      onTap: () {
                        Navigator.pop(context);
                        _showLeaveGroupDialog();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  
  void _showLeaveGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(groupProvider.notifier).leaveGroup(widget.groupId);
              if (mounted) {
                Navigator.pop(context); // Return to groups list
              }
            },
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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
    
    // Find the sender's name for display
    final groupState = ref.watch(groupProvider);
    final groupMembers = groupState.valueOrNull?.currentGroupMembers ?? [];
    final currentUser = ref.read(currentUserProvider);
    
    String senderName = replyMessage.senderName;
    if (currentUser != null && replyMessage.senderUID == currentUser.uid) {
      senderName = 'yourself';
    } else if (groupMembers.isNotEmpty) {
      final sender = groupMembers.firstWhere(
        (member) => member.uid == replyMessage.senderUID,
        orElse: () => UserModel(
          uid: replyMessage.senderUID,
          name: replyMessage.senderName,
          phoneNumber: '',
          image: replyMessage.senderImage,
          aboutMe: '',
          lastSeen: '',
          token: '',
          createdAt: '',
          contactsUIDs: [],
          blockedUIDs: [],
        ),
      );
      senderName = sender.name;
    }
    
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
                  'Replying to $senderName',
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