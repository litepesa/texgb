// lib/features/groups/screens/group_chat_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:textgb/features/groups/providers/groups_providers.dart';
import 'package:textgb/features/groups/widgets/group_message_bubble.dart';
import 'package:textgb/features/groups/widgets/group_typing_indicator.dart';
import 'package:textgb/features/groups/screens/group_settings_screen.dart';
import 'package:textgb/features/groups/models/group_message_model.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';

class GroupChatScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupChatScreen({
    super.key,
    required this.groupId,
  });

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  bool _isTyping = false;
  bool _isUploadingMedia = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load more messages when scrolled to top
    if (_scrollController.position.pixels == 0) {
      ref.read(groupMessagesProvider(widget.groupId).notifier).loadMore();
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    ref.read(groupMessagesProvider(widget.groupId).notifier).sendMessage(
          messageText: text,
          mediaType: MessageMediaType.text,
        );

    _messageController.clear();
    _setTyping(false);

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _setTyping(bool typing) {
    if (_isTyping == typing) return;

    setState(() {
      _isTyping = typing;
    });

    final typingProvider = ref.read(typingIndicatorProvider(widget.groupId).notifier);
    if (typing) {
      typingProvider.sendTyping();
    } else {
      typingProvider.sendStopTyping();
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _AttachmentOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      _handleImagePicker();
                    },
                  ),
                  _AttachmentOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _handleCameraPicker();
                    },
                  ),
                  _AttachmentOption(
                    icon: Icons.insert_drive_file,
                    label: 'Document',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _handleFilePicker();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleImagePicker() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadAndSendMedia(File(image.path), MessageMediaType.image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: $e')),
        );
      }
    }
  }

  Future<void> _handleCameraPicker() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadAndSendMedia(File(image.path), MessageMediaType.image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  Future<void> _handleFilePicker() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        final fileSize = await file.length();

        if (fileSize > 50 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File size exceeds 50MB limit')),
            );
          }
          return;
        }

        await _uploadAndSendMedia(file, MessageMediaType.file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting file: $e')),
        );
      }
    }
  }

  Future<void> _uploadAndSendMedia(File file, MessageMediaType mediaType) async {
    setState(() {
      _isUploadingMedia = true;
    });

    try {
      // Upload to Cloudflare R2
      final authNotifier = ref.read(authenticationProvider.notifier);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.path.split('.').last;
      final reference = 'groups/${widget.groupId}/messages/$timestamp.$extension';

      final uploadedUrl = await authNotifier.storeFileToStorage(
        file: file,
        reference: reference,
      );

      // Send message with media URL
      await ref.read(groupMessagesProvider(widget.groupId).notifier).sendMessage(
            messageText: mediaType == MessageMediaType.image ? 'Image' : 'File',
            mediaUrl: uploadedUrl,
            mediaType: mediaType,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              mediaType == MessageMediaType.image
                  ? 'Image sent successfully'
                  : 'File sent successfully',
            ),
          ),
        );
      }

      // Scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send media: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingMedia = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupDetailProvider(widget.groupId));
    final messagesAsync = ref.watch(groupMessagesProvider(widget.groupId));
    final membersAsync = ref.watch(groupMembersProvider(widget.groupId));
    final typingUsers = ref.watch(typingIndicatorProvider(widget.groupId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: groupAsync.when(
          data: (group) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.name,
                style: const TextStyle(fontSize: 16),
              ),
              membersAsync.when(
                data: (members) => Text(
                  '${members.length} ${members.length == 1 ? 'member' : 'members'}',
                  style: const TextStyle(fontSize: 12),
                ),
                loading: () => const Text(
                  'Loading...',
                  style: TextStyle(fontSize: 12),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Error'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupSettingsScreen(groupId: widget.groupId),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start the conversation',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUser?.uid;

                    // Show sender name if not from current user and different from previous
                    final showSender = !isMe &&
                        (index == 0 ||
                            messages[index - 1].senderId != message.senderId);

                    return GroupMessageBubble(
                      message: message,
                      isMe: isMe,
                      showSender: showSender,
                      onDelete: () {
                        ref
                            .read(groupMessagesProvider(widget.groupId).notifier)
                            .deleteMessage(message.id);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(groupMessagesProvider(widget.groupId));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Typing indicator
          if (typingUsers.isNotEmpty)
            GroupTypingIndicator(
              typingText: ref
                  .read(typingIndicatorProvider(widget.groupId).notifier)
                  .getTypingText(),
            ),

          // Message input
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Media picker button
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _isUploadingMedia ? null : _showAttachmentOptions,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (text) {
                      _setTyping(text.isNotEmpty);
                    },
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Supporting widget for attachment options
class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
