// lib/features/chat/screens/chat_screen.dart
// UPDATED: Cleaned up for offline-first architecture
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/features/chat/providers/message_provider.dart';
import 'package:textgb/features/chat/widgets/message_input.dart';
import 'package:textgb/features/chat/widgets/swipe_to_wrapper.dart';
import 'package:textgb/features/chat/widgets/video_player_overlay.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final UserModel contact;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.contact,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottom = false;
  double _fontSize = 16.0;
  bool _hasMessageBeenSent = false;
  
  // Video player state
  bool _isVideoPlayerVisible = false;
  String? _currentVideoUrl;

  // RFC 3339 date formatters for Go backend compatibility
  static final DateFormat _rfc3339Format = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
  static final DateFormat _displayDateFormat = DateFormat('MMM dd, HH:mm');
  static final DateFormat _searchDateFormat = DateFormat('MMM dd, yyyy HH:mm');
  
  // Helper method to format timestamp to RFC 3339 for Go backend
  String _formatTimestampToRFC3339(DateTime timestamp) {
    final utcTimestamp = timestamp.toUtc();
    return _rfc3339Format.format(utcTimestamp);
  }
  
  // Helper method to parse RFC 3339 timestamp from Go backend
  DateTime _parseRFC3339Timestamp(String rfc3339String) {
    try {
      return _rfc3339Format.parse(rfc3339String, true).toLocal();
    } catch (e) {
      debugPrint('Error parsing RFC 3339 timestamp: $e');
      return DateTime.now();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_scrollListener);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _markMessagesAsRead();
    }
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final showButton = _scrollController.offset > 200;
      if (showButton != _showScrollToBottom) {
        setState(() {
          _showScrollToBottom = showButton;
        });
      }
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

  void _markMessagesAsRead() {
    final messageNotifier = ref.read(messageNotifierProvider(widget.chatId).notifier);
    final currentUser = ref.read(currentUserProvider);
    
    if (currentUser != null) {
      final messageState = ref.read(messageNotifierProvider(widget.chatId)).valueOrNull;
      if (messageState != null) {
        final unreadMessageIds = messageState.messages
            .where((msg) => msg.senderId != currentUser.uid && !msg.isReadBy(currentUser.uid))
            .map((msg) => msg.messageId)
            .toList();
        
        if (unreadMessageIds.isNotEmpty) {
          messageNotifier.markMessagesAsDelivered(widget.chatId, unreadMessageIds);
        }
      }
    }
  }

  void _handleVideoThumbnailTap(MessageModel message) {
    String? videoUrl;
    
    if (message.type == MessageEnum.video) {
      videoUrl = message.mediaUrl;
    } else if (message.mediaMetadata?['isVideoReaction'] == true) {
      final videoReactionData = message.mediaMetadata?['videoReaction'];
      if (videoReactionData != null) {
        videoUrl = videoReactionData['videoUrl'];
      }
    }
    
    if (videoUrl == null || videoUrl.isEmpty) {
      showSnackBar(context, 'Video not available');
      return;
    }
    
    _showVideoPlayer(videoUrl);
  }

  void _showVideoPlayer(String videoPath) {
    setState(() {
      _currentVideoUrl = videoPath;
      _isVideoPlayerVisible = true;
    });
  }

  void _closeVideoPlayer() {
    setState(() {
      _isVideoPlayerVisible = false;
      _currentVideoUrl = null;
    });
  }

  Widget _buildContactAvatar({double radius = 18}) {
    if (widget.contact.profileImage.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: context.modernTheme.primaryColor?.withOpacity(0.2),
        child: Text(
          widget.contact.name.isNotEmpty 
            ? widget.contact.name[0].toUpperCase()
            : '?',
          style: TextStyle(
            color: context.modernTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.6,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: widget.contact.profileImage,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: context.modernTheme.primaryColor?.withOpacity(0.2),
        child: SizedBox(
          width: radius,
          height: radius,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.modernTheme.primaryColor,
          ),
        ),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: radius,
        backgroundColor: context.modernTheme.primaryColor?.withOpacity(0.2),
        child: Text(
          widget.contact.name.isNotEmpty 
            ? widget.contact.name[0].toUpperCase()
            : '?',
          style: TextStyle(
            color: context.modernTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.6,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final chatTheme = context.chatTheme;
    final currentUser = ref.watch(currentUserProvider);
    final messageState = ref.watch(messageNotifierProvider(widget.chatId));
    
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('User not authenticated')),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (_isVideoPlayerVisible) {
          _closeVideoPlayer();
          return false;
        }
        
        Navigator.of(context).pop(_hasMessageBeenSent);
        return false;
      },
      child: Scaffold(
        backgroundColor: chatTheme.chatBackgroundColor,
        appBar: _buildAppBar(modernTheme),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: messageState.when(
                    loading: () => _buildLoadingState(modernTheme),
                    error: (error, stack) => _buildErrorState(modernTheme, error.toString()),
                    data: (state) => _buildMessagesList(state, currentUser),
                  ),
                ),
                
                if (!_isVideoPlayerVisible)
                  messageState.maybeWhen(
                    data: (state) => MessageInput(
                      onSendText: (text) => _handleSendText(text),
                      onSendImage: (image) => _handleSendImage(image),
                      onSendFile: (file, fileName) => _handleSendFile(file, fileName),
                      contactName: widget.contact.name,
                      replyToMessage: state.replyToMessage,
                      onCancelReply: () => _cancelReply(),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
              ],
            ),
            
            if (_isVideoPlayerVisible && _currentVideoUrl != null)
              VideoPlayerOverlay(
                videoUrl: _currentVideoUrl!,
                onClose: _closeVideoPlayer,
                title: 'Shared Video',
              ),
              
            if (_showScrollToBottom && !_isVideoPlayerVisible)
              Positioned(
                right: 8,
                bottom: 80,
                child: FloatingActionButton.small(
                  onPressed: _scrollToBottom,
                  backgroundColor: modernTheme.primaryColor?.withOpacity(0.3),
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.keyboard_arrow_down),
                ),
              ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ModernThemeExtension modernTheme) {
    final isVerified = widget.contact.isVerified;
    
    return AppBar(
      backgroundColor: modernTheme.appBarColor?.withOpacity(0.95),
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(_hasMessageBeenSent),
        icon: Icon(Icons.arrow_back, color: modernTheme.textColor),
      ),
      title: GestureDetector(
        onTap: () => _showContactProfile(),
        child: Row(
          children: [
            _buildContactAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contact.name,
                    style: TextStyle(
                      color: modernTheme.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isVerified ? Icons.verified : Icons.help_outline,
                        size: 12,
                        color: isVerified ? Colors.blue : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isVerified ? 'Verified' : 'Not Verified',
                        style: TextStyle(
                          color: isVerified ? Colors.blue : Colors.grey[600],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _showSearchDialog(),
          icon: Icon(Icons.search, color: modernTheme.textColor),
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: modernTheme.textColor),
          color: modernTheme.surfaceColor,
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'pinned_messages',
              child: Row(
                children: [
                  Icon(Icons.push_pin, color: modernTheme.textColor, size: 20),
                  const SizedBox(width: 12),
                  Text('Pinned Messages', style: TextStyle(color: modernTheme.textColor)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'font_size',
              child: Row(
                children: [
                  Icon(Icons.text_fields, color: modernTheme.textColor, size: 20),
                  const SizedBox(width: 12),
                  Text('Font Size', style: TextStyle(color: modernTheme.textColor)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'block',
              child: const Row(
                children: [
                  Icon(Icons.block, color: Colors.red, size: 20),
                  SizedBox(width: 12),
                  Text('Block Contact', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState(ModernThemeExtension modernTheme) {
    return Center(
      child: CircularProgressIndicator(color: modernTheme.primaryColor),
    );
  }

  Widget _buildErrorState(ModernThemeExtension modernTheme, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: modernTheme.textSecondaryColor),
          const SizedBox(height: 16),
          Text(
            'Failed to load messages',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: modernTheme.textSecondaryColor, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(MessageState state, UserModel currentUser) {
    if (state.messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final message = state.messages[index];
        final isCurrentUser = message.senderId == currentUser.uid;
        final isLastInGroup = _isLastInGroup(state.messages, index);
        
        return SwipeToWrapper(
          message: message,
          isCurrentUser: isCurrentUser,
          isLastInGroup: isLastInGroup,
          fontSize: _fontSize,
          contactName: widget.contact.name,
          onLongPress: () => _showMessageOptions(message, isCurrentUser),
          onVideoTap: () => _handleVideoThumbnailTap(message),
          onRightSwipe: () => _replyToMessage(message),
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
          _buildContactAvatar(radius: 40),
          const SizedBox(height: 16),
          Text(
            'Start a conversation with ${widget.contact.name}',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to get started',
            style: TextStyle(color: modernTheme.textSecondaryColor, fontSize: 14),
          ),
        ],
      ),
    );
  }

  bool _isLastInGroup(List<MessageModel> messages, int index) {
    if (index == 0) return true;
    
    final currentMessage = messages[index];
    final nextMessage = messages[index - 1];
    
    return currentMessage.senderId != nextMessage.senderId ||
           nextMessage.timestamp.difference(currentMessage.timestamp).inMinutes > 5;
  }

  void _handleSendText(String text) {
    final messageNotifier = ref.read(messageNotifierProvider(widget.chatId).notifier);
    messageNotifier.sendTextMessage(widget.chatId, text);
    _hasMessageBeenSent = true;
  }

  void _handleSendImage(File image) {
    final messageNotifier = ref.read(messageNotifierProvider(widget.chatId).notifier);
    messageNotifier.sendImageMessage(widget.chatId, image);
    _hasMessageBeenSent = true;
  }

  void _handleSendFile(File file, String fileName) {
    final messageNotifier = ref.read(messageNotifierProvider(widget.chatId).notifier);
    messageNotifier.sendFileMessage(widget.chatId, file, fileName);
    _hasMessageBeenSent = true;
  }

  void _cancelReply() {
    ref.read(messageNotifierProvider(widget.chatId).notifier).cancelReply();
  }

  void _replyToMessage(MessageModel message) {
    ref.read(messageNotifierProvider(widget.chatId).notifier).setReplyToMessage(message);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _showMessageOptions(MessageModel message, bool isCurrentUser) {
    final modernTheme = context.modernTheme;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: modernTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: modernTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              _MessageActionTile(
                icon: Icons.reply,
                title: 'Reply',
                onTap: () {
                  Navigator.pop(context);
                  _replyToMessage(message);
                },
              ),
              
              if (isCurrentUser && message.type == MessageEnum.text)
                _MessageActionTile(
                  icon: Icons.edit,
                  title: 'Edit',
                  onTap: () {
                    Navigator.pop(context);
                    _editMessage(message);
                  },
                ),
              
              _MessageActionTile(
                icon: message.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                title: message.isPinned ? 'Unpin' : 'Pin',
                onTap: () {
                  Navigator.pop(context);
                  _togglePinMessage(message);
                },
              ),
              
              if (message.type == MessageEnum.text || 
                  message.mediaMetadata?['isVideoReaction'] == true)
                _MessageActionTile(
                  icon: Icons.copy,
                  title: 'Copy',
                  onTap: () {
                    Navigator.pop(context);
                    _copyMessage(message);
                  },
                ),
              
              if (isCurrentUser) ...[
                _MessageActionTile(
                  icon: Icons.delete_outline,
                  title: 'Delete for me',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMessage(message, false);
                  },
                ),
                _MessageActionTile(
                  icon: Icons.delete,
                  title: 'Delete for everyone',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteForEveryone(message);
                  },
                ),
              ] else
                _MessageActionTile(
                  icon: Icons.delete_outline,
                  title: 'Delete for me',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMessage(message, false);
                  },
                ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _editMessage(MessageModel message) {
    showDialog(
      context: context,
      builder: (context) => _EditMessageDialog(
        message: message,
        onEdit: (newContent) {
          ref.read(messageNotifierProvider(widget.chatId).notifier)
              .editMessage(widget.chatId, message.messageId, newContent);
        },
      ),
    );
  }

  void _togglePinMessage(MessageModel message) {
    ref.read(messageNotifierProvider(widget.chatId).notifier)
        .togglePinMessage(widget.chatId, message.messageId, message.isPinned);
  }

  void _copyMessage(MessageModel message) {
    String textToCopy = message.content;
    
    if (message.mediaMetadata?['isVideoReaction'] == true) {
      final videoReactionData = message.mediaMetadata?['videoReaction'];
      if (videoReactionData != null) {
        final reaction = videoReactionData['reaction'] ?? '';
        final userName = videoReactionData['userName'] ?? 'video';
        textToCopy = reaction.isNotEmpty ? reaction : 'Reacted to $userName\'s video';
      }
    }
    
    Clipboard.setData(ClipboardData(text: textToCopy));
    showSnackBar(context, 'Message copied to clipboard');
  }

  void _deleteMessage(MessageModel message, bool deleteForEveryone) {
    ref.read(messageNotifierProvider(widget.chatId).notifier)
        .deleteMessage(widget.chatId, message.messageId, deleteForEveryone);
  }

  void _confirmDeleteForEveryone(MessageModel message) {
    final modernTheme = context.modernTheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: modernTheme.surfaceColor,
        title: Text('Delete for everyone?', style: TextStyle(color: modernTheme.textColor)),
        content: Text(
          'This message will be deleted for everyone in this chat.',
          style: TextStyle(color: modernTheme.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: modernTheme.textSecondaryColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(message, true);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showContactProfile() {
    showSnackBar(context, 'Contact profile - Coming soon');
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => _SearchMessagesDialog(
        chatId: widget.chatId,
        onMessageSelected: (message) {
          Navigator.pop(context);
        },
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'pinned_messages':
        _showPinnedMessages();
        break;
      case 'font_size':
        _showFontSizeDialog();
        break;
      case 'block':
        _confirmBlockContact();
        break;
    }
  }

  void _showPinnedMessages() {
    final messageState = ref.read(messageNotifierProvider(widget.chatId)).valueOrNull;
    final pinnedMessages = messageState?.pinnedMessages ?? [];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.modernTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => _PinnedMessagesSheet(
          messages: pinnedMessages,
          scrollController: scrollController,
          onUnpin: (message) => _togglePinMessage(message),
        ),
      ),
    );
  }

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => _FontSizeDialog(
        currentSize: _fontSize,
        onSizeChanged: (size) => setState(() => _fontSize = size),
      ),
    );
  }

  void _confirmBlockContact() {
    final modernTheme = context.modernTheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: modernTheme.surfaceColor,
        title: Text(
          'Block ${widget.contact.name}?',
          style: TextStyle(color: modernTheme.textColor),
        ),
        content: Text(
          'Blocked contacts will not be able to send you messages.',
          style: TextStyle(color: modernTheme.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: modernTheme.textSecondaryColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              showSnackBar(context, 'Contact blocked');
              Navigator.pop(context);
            },
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// Supporting widgets
class _MessageActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;
  final VoidCallback onTap;

  const _MessageActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final effectiveColor = color ?? modernTheme.textColor;
    
    return ListTile(
      leading: Icon(icon, color: effectiveColor, size: 22),
      title: Text(
        title,
        style: TextStyle(color: effectiveColor, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _EditMessageDialog extends StatefulWidget {
  final MessageModel message;
  final Function(String) onEdit;

  const _EditMessageDialog({
    required this.message,
    required this.onEdit,
  });

  @override
  State<_EditMessageDialog> createState() => _EditMessageDialogState();
}

class _EditMessageDialogState extends State<_EditMessageDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.message.content);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return AlertDialog(
      backgroundColor: modernTheme.surfaceColor,
      title: Text('Edit Message', style: TextStyle(color: modernTheme.textColor)),
      content: TextField(
        controller: _controller,
        maxLines: 5,
        minLines: 1,
        autofocus: true,
        style: TextStyle(color: modernTheme.textColor),
        decoration: InputDecoration(
          hintText: 'Enter your message...',
          hintStyle: TextStyle(color: modernTheme.textSecondaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: modernTheme.dividerColor!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: modernTheme.primaryColor!),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: modernTheme.textSecondaryColor)),
        ),
        TextButton(
          onPressed: () {
            final newContent = _controller.text.trim();
            if (newContent.isNotEmpty && newContent != widget.message.content) {
              widget.onEdit(newContent);
            }
            Navigator.pop(context);
          },
          child: Text('Save', style: TextStyle(color: modernTheme.primaryColor)),
        ),
      ],
    );
  }
}

class _SearchMessagesDialog extends ConsumerStatefulWidget {
  final String chatId;
  final Function(MessageModel) onMessageSelected;

  const _SearchMessagesDialog({
    required this.chatId,
    required this.onMessageSelected,
  });

  @override
  ConsumerState<_SearchMessagesDialog> createState() => _SearchMessagesDialogState();
}

class _SearchMessagesDialogState extends ConsumerState<_SearchMessagesDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<MessageModel> _searchResults = [];
  bool _isSearching = false;
  static final DateFormat _searchDateFormat = DateFormat('MMM dd, yyyy HH:mm');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await ref.read(messageNotifierProvider(widget.chatId).notifier)
          .searchMessages(widget.chatId, query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Dialog(
      backgroundColor: modernTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Search Messages',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyle(color: modernTheme.textColor),
              decoration: InputDecoration(
                hintText: 'Search in chat...',
                hintStyle: TextStyle(color: modernTheme.textSecondaryColor),
                prefixIcon: Icon(Icons.search, color: modernTheme.textSecondaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: modernTheme.dividerColor!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: modernTheme.primaryColor!),
                ),
              ),
              onChanged: _performSearch,
            ),
            
            const SizedBox(height: 16),
            
            Expanded(
              child: _isSearching
                  ? Center(
                      child: CircularProgressIndicator(color: modernTheme.primaryColor),
                    )
                  : _searchResults.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.isEmpty
                                ? 'Enter text to search'
                                : 'No messages found',
                            style: TextStyle(color: modernTheme.textSecondaryColor),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final message = _searchResults[index];
                            return ListTile(
                              title: Text(
                                message.content,
                                style: TextStyle(color: modernTheme.textColor),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                _searchDateFormat.format(message.timestamp),
                                style: TextStyle(color: modernTheme.textSecondaryColor),
                              ),
                              onTap: () => widget.onMessageSelected(message),
                            );
                          },
                        ),
            ),
            
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: TextStyle(color: modernTheme.primaryColor)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinnedMessagesSheet extends StatelessWidget {
  final List<MessageModel> messages;
  final ScrollController scrollController;
  final Function(MessageModel) onUnpin;

  const _PinnedMessagesSheet({
    required this.messages,
    required this.scrollController,
    required this.onUnpin,
  });

  static final DateFormat _pinnedDateFormat = DateFormat('MMM dd, HH:mm');

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Container(
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: modernTheme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Pinned Messages',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      'No pinned messages',
                      style: TextStyle(color: modernTheme.textSecondaryColor),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return ListTile(
                        title: Text(
                          message.getDisplayContent(),
                          style: TextStyle(color: modernTheme.textColor),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          _pinnedDateFormat.format(message.timestamp),
                          style: TextStyle(color: modernTheme.textSecondaryColor),
                        ),
                        trailing: IconButton(
                          onPressed: () => onUnpin(message),
                          icon: Icon(
                            Icons.push_pin_outlined,
                            color: modernTheme.textSecondaryColor,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FontSizeDialog extends StatefulWidget {
  final double currentSize;
  final Function(double) onSizeChanged;

  const _FontSizeDialog({
    required this.currentSize,
    required this.onSizeChanged,
  });

  @override
  State<_FontSizeDialog> createState() => _FontSizeDialogState();
}

class _FontSizeDialogState extends State<_FontSizeDialog> {
  late double _fontSize;

  @override
  void initState() {
    super.initState();
    _fontSize = widget.currentSize;
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return AlertDialog(
      backgroundColor: modernTheme.surfaceColor,
      title: Text('Font Size', style: TextStyle(color: modernTheme.textColor)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Sample message text',
            style: TextStyle(color: modernTheme.textColor, fontSize: _fontSize),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text('Small', style: TextStyle(color: modernTheme.textSecondaryColor)),
              Expanded(
                child: Slider(
                  value: _fontSize,
                  min: 12.0,
                  max: 24.0,
                  divisions: 12,
                  activeColor: modernTheme.primaryColor,
                  onChanged: (value) => setState(() => _fontSize = value),
                ),
              ),
              Text('Large', style: TextStyle(color: modernTheme.textSecondaryColor)),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: modernTheme.textSecondaryColor)),
        ),
        TextButton(
          onPressed: () {
            widget.onSizeChanged(_fontSize);
            Navigator.pop(context);
          },
          child: Text('Apply', style: TextStyle(color: modernTheme.primaryColor)),
        ),
      ],
    );
  }
}