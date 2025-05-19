// lib/features/groups/screens/group_chat_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isLoading = true;
  bool _isNonMember = false;
  bool _canSendMessages = true;

  @override
  void initState() {
    super.initState();
    
    // Add observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize group chat when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyMembership();
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
      if (_isNonMember) return; // Skip if not a member
      ref.read(chatProvider.notifier).openGroupChat(widget.groupId, []);
    }
  }

  // Verify user's membership before showing chat
  Future<void> _verifyMembership() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      if (mounted) {
        showSnackBar(context, 'Authentication required');
        Navigator.pop(context);
      }
      return;
    }
    
    try {
      // Fetch latest group data
      await ref.read(groupProvider.notifier).getGroupDetails(widget.groupId);
      
      // Check if user is a member
      final groupState = ref.read(groupProvider);
      final group = groupState.valueOrNull?.currentGroup ?? widget.group;
      
      final isMember = group.isMember(currentUser.uid);
      final canSend = group.canSendMessages(currentUser.uid);
      
      if (!isMember) {
        if (mounted) {
          setState(() {
            _isNonMember = true;
            _canSendMessages = false;
            _isLoading = false;
          });
        }
        return;
      }
      
      setState(() {
        _canSendMessages = canSend;
      });
      
      // If membership verified, proceed with chat initialization
      ref.read(chatProvider.notifier).openGroupChat(widget.groupId, []);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    if (!_canSendMessages) {
      showSnackBar(context, 'You do not have permission to send messages in this group');
      return;
    }
    
    // Use sendGroupMessage instead of sendTextMessage for group chats
    ref.read(chatProvider.notifier).sendGroupMessage(
      message: _messageController.text,
      messageType: MessageEnum.text,
    ).then((_) {
      _messageController.clear();
    }).catchError((e) {
      showSnackBar(context, 'Error sending message: $e');
    });
  }

  void _toggleAttachmentMenu() {
    if (!_canSendMessages) {
      showSnackBar(context, 'You do not have permission to send messages in this group');
      return;
    }
    
    setState(() {
      _isAttachmentVisible = !_isAttachmentVisible;
    });
  }

  Future<void> _pickImage({required bool fromCamera}) async {
    if (!_canSendMessages) {
      showSnackBar(context, 'You do not have permission to send messages in this group');
      return;
    }
    
    final image = await pickImage(
      fromCamera: fromCamera,
      onFail: (error) => showSnackBar(context, error),
    );

    if (image != null) {
      // Use sendGroupMediaMessage for group chats
      ref.read(chatProvider.notifier).sendGroupMediaMessage(
        file: image,
        messageType: MessageEnum.image,
      ).catchError((e) {
        showSnackBar(context, 'Error sending image: $e');
      });
    }
    
    setState(() {
      _isAttachmentVisible = false;
    });
  }

  Future<void> _pickVideo({required bool fromCamera}) async {
    if (!_canSendMessages) {
      showSnackBar(context, 'You do not have permission to send messages in this group');
      return;
    }
    
    final video = fromCamera 
        ? await pickVideoFromCamera(onFail: (error) => showSnackBar(context, error))
        : await pickVideo(onFail: (error) => showSnackBar(context, error));

    if (video != null) {
      // Use sendGroupMediaMessage for group chats
      ref.read(chatProvider.notifier).sendGroupMediaMessage(
        file: video,
        messageType: MessageEnum.video,
      ).catchError((e) {
        showSnackBar(context, 'Error sending video: $e');
      });
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
    if (_isNonMember) return; // Non-members can't interact with messages
    
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
    if (_isNonMember) return; // Non-members can't reply
    ref.read(chatProvider.notifier).setReplyingTo(message);
  }
  
  // Handle joining the group
  void _handleJoinGroup() async {
    try {
      if (_isLoading) return;
      
      setState(() {
        _isLoading = true;
      });
      
      await ref.read(groupProvider.notifier).joinGroup(widget.groupId);
      
      if (mounted) {
        final group = ref.read(groupProvider).valueOrNull?.currentGroup ?? widget.group;
        
        if (group.isPrivate && group.approveMembers) {
          setState(() {
            _isLoading = false;
          });
          showSnackBar(context, 'Join request sent. Waiting for admin approval.');
        } else {
          // Successfully joined, refresh membership status
          await _verifyMembership();
          
          if (mounted) {
            showSnackBar(context, 'You have joined the group successfully!');
            setState(() {
              _isNonMember = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showSnackBar(context, 'Error joining group: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final chatTheme = context.chatTheme;
    
    // Watch group details
    final groupState = ref.watch(groupProvider);
    final group = groupState.valueOrNull?.currentGroup ?? widget.group;
    final groupMembers = groupState.valueOrNull?.currentGroupMembers ?? [];
    
    // Check current user status in the group
    final currentUser = ref.read(currentUserProvider);
    final isMember = currentUser != null && group.isMember(currentUser.uid);
    final canSend = currentUser != null && 
                  group.isMember(currentUser.uid) &&
                  (!group.lockMessages || group.isAdmin(currentUser.uid));
    
    // Update state variables if group status has changed
    if (isMember != !_isNonMember || canSend != _canSendMessages) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isNonMember = !isMember;
            _canSendMessages = canSend;
          });
        }
      });
    }
    
    // Watch messages stream for current group
    final messagesStream = _isNonMember 
        ? const AsyncValue<List<MessageModel>>.data([]) // Empty if not a member
        : ref.watch(messageStreamProvider(widget.groupId));
    final chatState = ref.watch(chatProvider);
    
    // Check if we're editing a message
    final bool isEditing = chatState.valueOrNull?.editingMessage != null;
    
    // Check if the group is at capacity
    final isAtCapacity = group.hasReachedMemberLimit();

    return Scaffold(
      backgroundColor: chatTheme.chatBackgroundColor,
      appBar: _buildGroupAppBar(context, group),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: modernTheme.primaryColor))
          : Column(
        children: [
          // Non-member warning banner
          if (_isNonMember)
            Container(
              color: Colors.red.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isAtCapacity
                          ? 'This group has reached its maximum member limit of ${GroupModel.MAX_MEMBERS}.'
                          : 'You are not a member of this group. Join the group to send messages.',
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  ),
                  if (!isAtCapacity)
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleJoinGroup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade800,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Join'),
                    ),
                ],
              ),
            ),
            
          // Admin-only messaging warning
          if (isMember && !canSend && group.lockMessages)
            Container(
              color: Colors.amber.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.lock, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Only admins can send messages in this group.',
                      style: TextStyle(color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),
          
          // Editing indicator
          if (isEditing && isMember)
            _buildEditingContainer(chatState.valueOrNull!.editingMessage!),
          
          // Reply UI if replying to a message
          if (!isEditing && chatState.valueOrNull?.replyingTo != null && isMember)
            _buildReplyContainer(chatState.valueOrNull!.replyingTo!),

          // Messages list
          Expanded(
            child: _isNonMember
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock,
                          size: 64,
                          color: modernTheme.textSecondaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'This group is private',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: modernTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text(
                            isAtCapacity
                                ? 'This group has reached its maximum member limit of ${GroupModel.MAX_MEMBERS}.'
                                : 'You need to join this group to view messages',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: modernTheme.textSecondaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (!isAtCapacity)
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _handleJoinGroup,
                            icon: const Icon(Icons.group_add),
                            label: Text(_isLoading ? 'Joining...' : 'Join Group'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: modernTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : messagesStream.when(
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
          if (_isAttachmentVisible && !_isNonMember && canSend) _buildAttachmentMenu(),

          // Chat input
          if (_isNonMember)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: isAtCapacity ? null : _handleJoinGroup,
                icon: Icon(isAtCapacity ? Icons.error_outline : Icons.group_add),
                label: Text(isAtCapacity 
                    ? 'Group Full (${GroupModel.MAX_MEMBERS} Members)' 
                    : 'Join Group to Send Messages'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAtCapacity ? Colors.grey : modernTheme.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  disabledBackgroundColor: Colors.grey,
                  disabledForegroundColor: Colors.white,
                ),
              ),
            )
          else if (!canSend)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Only admins can send messages in this group',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
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
    final isMember = !_isNonMember;
    
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
            Stack(
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
                // Member count indicator for large groups
                if (group.membersUIDs.length > 50)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: group.hasReachedMemberLimit()
                            ? Colors.red
                            : (group.isApproachingMemberLimit()
                                ? Colors.orange
                                : Colors.green),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: modernTheme.backgroundColor!,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '${group.membersUIDs.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
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
                    '${group.membersUIDs.length}/${GroupModel.MAX_MEMBERS} members',
                    style: TextStyle(
                      fontSize: 12,
                      color: group.hasReachedMemberLimit()
                          ? Colors.red
                          : (group.isApproachingMemberLimit()
                              ? Colors.orange
                              : modernTheme.textSecondaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Only show these actions for members
        if (isMember) ...[
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
        ],
        // Group settings button (always available)
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
                        leading: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.person_add),
                            Positioned(
                              right: -8,
                              top: -8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${group.awaitingApprovalUIDs.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
                    if (isMember)
                      ListTile(
                        leading: const Icon(Icons.search),
                        title: const Text('Search Messages'),
                        onTap: () {
                          Navigator.pop(context);
                          // TODO: Implement search
                          showSnackBar(context, 'Message search coming soon');
                        },
                      ),
                    if (isMember)
                      ListTile(
                        leading: const Icon(Icons.share),
                        title: const Text('Share Group'),
                        onTap: () {
                          Navigator.pop(context);
                          _shareGroup(group);
                        },
                      ),
                    if (isMember)
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
  
  void _shareGroup(GroupModel group) {
    try {
      final joinCode = group.getJoiningCode();
      
      // Check if group is near member limit before sharing
      final remainingSlots = GroupModel.MAX_MEMBERS - group.membersUIDs.length;
      if (remainingSlots <= 10) {
        // Show warning dialog first
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Group Nearly Full'),
            content: Text(
              'This group has only $remainingSlots ${remainingSlots == 1 ? 'slot' : 'slots'} '
              'remaining out of ${GroupModel.MAX_MEMBERS}. Do you still want to share the invite link?'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showShareDialog(group, joinCode);
                },
                child: Text('Continue Sharing'),
              ),
            ],
          ),
        );
      } else {
        _showShareDialog(group, joinCode);
      }
    } catch (e) {
      showSnackBar(context, 'Error sharing group: $e');
    }
  }
  
  void _showShareDialog(GroupModel group, String joinCode) {
    final shareText = 'Join my group "${group.groupName}" on TextGB! Use this code: $joinCode';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Share this group code with friends:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: context.modernTheme.surfaceVariantColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    joinCode,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () async {
                      // Copy to clipboard
                      await Clipboard.setData(ClipboardData(text: joinCode));
                      if (context.mounted) {
                        Navigator.pop(context);
                        showSnackBar(context, 'Group code copied to clipboard');
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: shareText));
              if (context.mounted) {
                Navigator.pop(context);
                showSnackBar(context, 'Share message copied to clipboard');
              }
            },
            child: const Text('Copy Message'),
          ),
        ],
      ),
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