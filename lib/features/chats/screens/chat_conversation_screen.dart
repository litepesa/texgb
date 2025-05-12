import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/chats/models/chat_message_model.dart';
import 'package:textgb/features/chats/providers/chat_activity_provider.dart';
import 'package:textgb/features/chats/providers/draft_provider.dart';
import 'package:textgb/features/chats/providers/message_provider.dart';
import 'package:textgb/features/chats/widgets/chat_appbar.dart';
import 'package:textgb/features/chats/widgets/chat_input_field.dart';
import 'package:textgb/features/chats/widgets/message_list.dart';
import 'package:textgb/features/contacts/screens/contact_profile_screen.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/widgets/error_widget.dart';

class ChatConversationScreen extends ConsumerStatefulWidget {
  final UserModel contact;

  const ChatConversationScreen({
    Key? key,
    required this.contact,
  }) : super(key: key);

  @override
  ConsumerState<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends ConsumerState<ChatConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  bool _isRecording = false;
  bool _isTyping = false;
  ChatMessageModel? _replyMessage;
  MessageEnum _messageType = MessageEnum.text;
  File? _mediaFile;
  bool _isAttachmentMenuVisible = false;

  @override
  void initState() {
    super.initState();
    _loadDraftMessage();

    // Set up focus node listener to detect when user is typing
    _messageFocusNode.addListener(() {
      if (_messageFocusNode.hasFocus) {
        _notifyTyping(true);
      } else {
        _notifyTyping(false);
      }
    });

    // Set up controller listener to detect typing state
    _messageController.addListener(() {
      final isCurrentlyTyping = _messageController.text.isNotEmpty;
      if (_isTyping != isCurrentlyTyping) {
        _isTyping = isCurrentlyTyping;
        _notifyTyping(isCurrentlyTyping);
      }
    });
  }

  @override
  void dispose() {
    // Save draft message
    _saveDraftMessage();
    
    // Clean up controllers and listeners
    _messageFocusNode.removeListener(() {});
    _messageController.removeListener(() {});
    _messageController.dispose();
    _messageFocusNode.dispose();
    
    // Turn off typing indicator when leaving chat
    _notifyTyping(false);
    
    super.dispose();
  }

  void _notifyTyping(bool isTyping) {
    final activityNotifier = ref.read(chatActivityProvider(widget.contact.uid).notifier);
    activityNotifier.setTypingStatus(isTyping: isTyping);
  }

  Future<void> _loadDraftMessage() async {
    final draftState = await ref.read(draftProvider(widget.contact.uid).future);
    if (draftState.draft != null) {
      setState(() {
        _messageController.text = draftState.draft!.message;
        _messageType = draftState.draft!.messageType;
        // Handle reply data if needed
        if (draftState.draft!.repliedMessage != null) {
          // We would need to construct a ChatMessageModel here
          // This is a simplified version
          _replyMessage = null; // Can't fully reconstruct from draft
        }
        // Handle media path if needed
        if (draftState.draft!.mediaPath != null) {
          _mediaFile = File(draftState.draft!.mediaPath!);
        }
      });
    }
  }

  Future<void> _saveDraftMessage() async {
    if (_messageController.text.isEmpty && _mediaFile == null && _replyMessage == null) {
      // No need to save empty draft
      return;
    }

    final draftNotifier = ref.read(draftProvider(widget.contact.uid).notifier);
    await draftNotifier.updateDraftContent(
      message: _messageController.text,
    );

    if (_mediaFile != null) {
      await draftNotifier.updateDraftMedia(
        mediaPath: _mediaFile!.path,
        messageType: _messageType,
      );
    }

    if (_replyMessage != null) {
      await draftNotifier.updateDraftReply(
        repliedMessage: _replyMessage!.message,
        repliedTo: _replyMessage!.senderUID,
        repliedMessageType: _replyMessage!.messageType,
      );
    }
  }

  void _sendTextMessage() {
    if (_messageController.text.trim().isEmpty && _mediaFile == null) return;

    final messageNotifier = ref.read(messageProvider(widget.contact.uid).notifier);

    if (_mediaFile != null) {
      _sendMediaMessage();
      return;
    }

    messageNotifier.sendTextMessage(
      message: _messageController.text.trim(),
      repliedMessage: _replyMessage?.message,
      repliedTo: _replyMessage?.senderUID,
      repliedMessageType: _replyMessage?.messageType,
    );

    // Clear input and reply
    _clearInput();
  }

  void _sendMediaMessage() async {
    if (_mediaFile == null) return;

    final messageNotifier = ref.read(messageProvider(widget.contact.uid).notifier);
    
    // Message caption (optional)
    final caption = _messageController.text.trim();

    try {
      await messageNotifier.sendMediaMessage(
        file: _mediaFile!,
        messageType: _messageType,
        message: caption,
        repliedMessage: _replyMessage?.message,
        repliedTo: _replyMessage?.senderUID,
        repliedMessageType: _replyMessage?.messageType,
      );

      // Clear everything
      _clearInput();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending media: ${e.toString()}')),
      );
    }
  }

  Future<void> _selectImage() async {
    final ImagePicker picker = ImagePicker();
    
    setState(() {
      _isAttachmentMenuVisible = false;
    });

    final bottomSheetColor = Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF262624) 
        : Colors.white;

    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: bottomSheetColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(context, 'camera');
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context, 'gallery');
                },
              ),
            ],
          ),
        );
      },
    );

    if (result == null) return;

    final XFile? image = await picker.pickImage(
      source: result == 'camera' ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        _mediaFile = File(image.path);
        _messageType = MessageEnum.image;
      });
    }
  }

  Future<void> _selectVideo() async {
    final ImagePicker picker = ImagePicker();
    
    setState(() {
      _isAttachmentMenuVisible = false;
    });

    final bottomSheetColor = Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF262624) 
        : Colors.white;

    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: bottomSheetColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Record a video'),
                onTap: () {
                  Navigator.pop(context, 'camera');
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context, 'gallery');
                },
              ),
            ],
          ),
        );
      },
    );

    if (result == null) return;

    final XFile? video = await picker.pickVideo(
      source: result == 'camera' ? ImageSource.camera : ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );

    if (video != null) {
      setState(() {
        _mediaFile = File(video.path);
        _messageType = MessageEnum.video;
      });
    }
  }

  void _clearInput() {
    setState(() {
      _messageController.clear();
      _replyMessage = null;
      _mediaFile = null;
      _messageType = MessageEnum.text;
      
      // Also clear the draft
      final draftNotifier = ref.read(draftProvider(widget.contact.uid).notifier);
      draftNotifier.deleteDraft();
    });
  }

  void _toggleAttachmentMenu() {
    setState(() {
      _isAttachmentMenuVisible = !_isAttachmentMenuVisible;
    });
  }

  void _handleReply(ChatMessageModel message) {
    setState(() {
      _replyMessage = message;
      // Focus the text field
      _messageFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final chatTheme = Theme.of(context).extension<ChatThemeExtension>()!;
    final messagesProvider = ref.watch(messageProvider(widget.contact.uid));
    final activityProvider = ref.watch(chatActivityProvider(widget.contact.uid));

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: ChatAppBar(
          contact: widget.contact,
          activityState: activityProvider.valueOrNull,
          onProfileTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ContactProfileScreen(contact: widget.contact),
              ),
            );
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: chatTheme.chatBackgroundColor,
          image: const DecorationImage(
            image: AssetImage('assets/images/chat_background.png'),
            fit: BoxFit.cover,
            opacity: 0.12,
          ),
        ),
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: messagesProvider.when(
                data: (messages) {
                  return MessageList(
                    messages: messages,
                    onReplyMessage: _handleReply,
                  );
                },
                error: (error, stack) => CustomErrorWidget(
                  error: error.toString(),
                  onRetry: () => ref.refresh(messageProvider(widget.contact.uid)),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
            ),
            
            // Attachment options menu
            if (_isAttachmentMenuVisible)
              _buildAttachmentMenu(),
            
            // Media preview if selected
            if (_mediaFile != null)
              _buildMediaPreview(),
              
            // Reply preview if replying
            if (_replyMessage != null)
              _buildReplyPreview(),
            
            // Message input field
            ChatInputField(
              controller: _messageController,
              focusNode: _messageFocusNode,
              onSendMessage: _sendTextMessage,
              onAttachmentTap: _toggleAttachmentMenu,
              onMicTap: () {
                // Handle voice recording
              },
              isRecording: _isRecording,
              onCancelRecording: () {
                setState(() {
                  _isRecording = false;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentMenu() {
    final modernTheme = context.modernTheme;
    final icons = [
      {'icon': Icons.image, 'label': 'Photo', 'color': Colors.purple, 'onTap': _selectImage},
      {'icon': Icons.videocam, 'label': 'Video', 'color': Colors.red, 'onTap': _selectVideo},
      {'icon': Icons.insert_drive_file, 'label': 'Document', 'color': Colors.blue, 'onTap': () {}},
      {'icon': Icons.mic, 'label': 'Audio', 'color': Colors.orange, 'onTap': () {}},
      {'icon': Icons.location_on, 'label': 'Location', 'color': Colors.green, 'onTap': () {}},
      {'icon': Icons.person, 'label': 'Contact', 'color': Colors.teal, 'onTap': () {}},
    ];

    return Container(
      color: modernTheme.surfaceColor,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: icons.map((item) {
          return InkWell(
            onTap: item['onTap'] as Function(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    item['icon'] as IconData,
                    color: item['color'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: modernTheme.textColor,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMediaPreview() {
    final modernTheme = context.modernTheme;
    final fileExtension = _mediaFile!.path.split('.').last.toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileExtension);
    
    return Container(
      color: modernTheme.surfaceColor?.withOpacity(0.9),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isImage ? Icons.image : Icons.video_file,
                color: modernTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isImage ? 'Photo' : 'Video',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                color: modernTheme.textColor,
                iconSize: 20,
                onPressed: () {
                  setState(() {
                    _mediaFile = null;
                    _messageType = MessageEnum.text;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: isImage
                  ? Image.file(
                      _mediaFile!,
                      fit: BoxFit.cover,
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          'assets/images/video_placeholder.jpg',
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                        const Icon(
                          Icons.play_circle_fill,
                          color: Colors.white,
                          size: 48,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    final modernTheme = context.modernTheme;
    
    return Container(
      color: modernTheme.surfaceColor?.withOpacity(0.9),
      padding: const EdgeInsets.all(8.0),
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
                  _replyMessage!.isMe ? 'You' : widget.contact.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: modernTheme.primaryColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _replyMessage!.messageType == MessageEnum.text
                      ? _replyMessage!.message
                      : _replyMessage!.messageType.displayName,
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            color: modernTheme.textColor,
            iconSize: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                _replyMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }}