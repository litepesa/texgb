// lib/features/chat/widgets/message_bubble.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class MessageBubble extends ConsumerStatefulWidget {
  final MessageModel message;
  final MessageModel? previousMessage;
  final MessageModel? nextMessage;
  final UserModel contact;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Function(MessageModel)? onSwipeToReply;
  final bool showAvatar;
  final bool showTimestamp;

  const MessageBubble({
    Key? key,
    required this.message,
    this.previousMessage,
    this.nextMessage,
    required this.contact,
    this.onTap,
    this.onLongPress,
    this.onSwipeToReply,
    this.showAvatar = true,
    this.showTimestamp = true,
  }) : super(key: key);

  @override
  ConsumerState<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends ConsumerState<MessageBubble>
    with TickerProviderStateMixin {
  late AnimationController _appearanceController;
  late AnimationController _pressController;
  late AnimationController _swipeController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pressScaleAnimation;
  late Animation<double> _swipeAnimation;
  late Animation<Color?> _swipeColorAnimation;

  bool _isPressed = false;
  double _swipeOffset = 0.0;
  bool _isSwipeActive = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAppearanceAnimation();
  }

  void _initializeAnimations() {
    // Appearance animation
    _appearanceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _appearanceController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _appearanceController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _appearanceController,
      curve: Curves.elasticOut,
    ));

    // Press animation
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _pressScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeInOut,
    ));

    // Swipe animation
    _swipeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _swipeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.elasticOut,
    ));

    _swipeColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: ref.read(currentUserProvider) != null 
          ? Theme.of(context).primaryColor.withOpacity(0.1)
          : Colors.transparent,
    ).animate(_swipeController);
  }

  void _startAppearanceAnimation() {
    Future.delayed(Duration(milliseconds: widget.message.hashCode % 100), () {
      if (mounted) {
        _appearanceController.forward();
      }
    });
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _pressController.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  void _handlePanStart(DragStartDetails details) {
    setState(() => _isSwipeActive = true);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isSwipeActive) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final isMyMessage = widget.message.senderUID == currentUser.uid;
    final swipeDirection = isMyMessage ? -1.0 : 1.0;
    final delta = details.delta.dx * swipeDirection;

    if (delta > 0) {
      setState(() {
        _swipeOffset = (delta / 100).clamp(0.0, 1.0);
      });

      _swipeController.value = _swipeOffset;

      // Haptic feedback at threshold
      if (_swipeOffset >= 0.6 && _swipeOffset < 0.65) {
        HapticFeedback.mediumImpact();
      }
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() => _isSwipeActive = false);

    if (_swipeOffset >= 0.6) {
      // Trigger reply
      HapticFeedback.heavyImpact();
      widget.onSwipeToReply?.call(widget.message);
    }

    // Reset swipe state
    setState(() => _swipeOffset = 0.0);
    _swipeController.reverse();
  }

  @override
  void dispose() {
    _appearanceController.dispose();
    _pressController.dispose();
    _swipeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const SizedBox.shrink();

    final isMyMessage = widget.message.senderUID == currentUser.uid;
    final modernTheme = context.modernTheme;
    final chatTheme = context.chatTheme;

    // Check if message should be grouped with previous
    final shouldGroupWithPrevious = _shouldGroupWithPrevious();
    final shouldGroupWithNext = _shouldGroupWithNext();

    return AnimatedBuilder(
      animation: Listenable.merge([
        _appearanceController,
        _pressController,
        _swipeController,
      ]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Transform.scale(
              scale: _scaleAnimation.value * _pressScaleAnimation.value,
              child: Container(
                margin: EdgeInsets.only(
                  top: shouldGroupWithPrevious ? 2 : 8,
                  bottom: shouldGroupWithNext ? 2 : 8,
                  left: isMyMessage ? 60 : 12,
                  right: isMyMessage ? 12 : 60,
                ),
                child: GestureDetector(
                  onTap: widget.onTap,
                  onLongPress: widget.onLongPress,
                  onTapDown: _handleTapDown,
                  onTapUp: _handleTapUp,
                  onTapCancel: _handleTapCancel,
                  onPanStart: _handlePanStart,
                  onPanUpdate: _handlePanUpdate,
                  onPanEnd: _handlePanEnd,
                  child: Stack(
                    children: [
                      // Swipe background
                      if (_isSwipeActive && _swipeOffset > 0)
                        _buildSwipeBackground(isMyMessage),
                      
                      // Main message content
                      Row(
                        mainAxisAlignment: isMyMessage
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Avatar for received messages
                          if (!isMyMessage && widget.showAvatar && !shouldGroupWithNext)
                            _buildAvatar(),
                          
                          if (!isMyMessage && widget.showAvatar && shouldGroupWithNext)
                            const SizedBox(width: 40),

                          // Message bubble
                          Flexible(
                            child: _buildMessageBubble(isMyMessage, chatTheme, modernTheme),
                          ),

                          // Avatar for sent messages (optional for future features)
                          if (isMyMessage && widget.showAvatar && !shouldGroupWithNext)
                            const SizedBox(width: 8),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSwipeBackground(bool isMyMessage) {
    return Positioned.fill(
      child: Container(
        alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
        padding: EdgeInsets.only(
          left: isMyMessage ? 0 : 20,
          right: isMyMessage ? 20 : 0,
        ),
        decoration: BoxDecoration(
          color: _swipeColorAnimation.value,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Transform.scale(
          scale: 0.8 + (_swipeOffset * 0.4),
          child: Icon(
            Icons.reply_rounded,
            color: Theme.of(context).primaryColor.withOpacity(_swipeOffset),
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        backgroundImage: widget.contact.image.isNotEmpty
            ? CachedNetworkImageProvider(widget.contact.image)
            : null,
        child: widget.contact.image.isEmpty
            ? Text(
                _getAvatarInitials(widget.contact.name),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildMessageBubble(bool isMyMessage, ChatThemeExtension chatTheme, ModernThemeExtension modernTheme) {
    final shouldGroupWithPrevious = _shouldGroupWithPrevious();
    final shouldGroupWithNext = _shouldGroupWithNext();

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
        minWidth: 60,
      ),
      decoration: BoxDecoration(
        gradient: _getBubbleGradient(isMyMessage, modernTheme),
        borderRadius: _getBubbleRadius(isMyMessage, shouldGroupWithPrevious, shouldGroupWithNext),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: _getBubbleRadius(isMyMessage, shouldGroupWithPrevious, shouldGroupWithNext),
          onTap: widget.onTap,
          child: Container(
            padding: _getBubblePadding(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sender name for group chats
                if (!isMyMessage && !shouldGroupWithPrevious)
                  _buildSenderName(modernTheme),

                // Reply preview
                if (widget.message.repliedMessage != null)
                  _buildReplyPreview(isMyMessage, modernTheme),

                // Message content
                _buildMessageContent(isMyMessage, chatTheme),

                // Reactions
                if (widget.message.reactions.isNotEmpty)
                  _buildReactions(modernTheme),

                // Timestamp and status
                _buildTimestampAndStatus(isMyMessage, chatTheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  LinearGradient _getBubbleGradient(bool isMyMessage, ModernThemeExtension modernTheme) {
    if (isMyMessage) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          modernTheme.primaryColor ?? Colors.blue,
          (modernTheme.primaryColor ?? Colors.blue).withOpacity(0.8),
        ],
      );
    } else {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          modernTheme.surfaceColor ?? Colors.grey[100]!,
          (modernTheme.surfaceColor ?? Colors.grey[100]!).withOpacity(0.95),
        ],
      );
    }
  }

  BorderRadius _getBubbleRadius(bool isMyMessage, bool groupedTop, bool groupedBottom) {
    const mainRadius = Radius.circular(20);
    const groupedRadius = Radius.circular(4);
    const tailRadius = Radius.circular(4);

    if (isMyMessage) {
      return BorderRadius.only(
        topLeft: mainRadius,
        topRight: groupedTop ? groupedRadius : mainRadius,
        bottomLeft: mainRadius,
        bottomRight: groupedBottom ? groupedRadius : tailRadius,
      );
    } else {
      return BorderRadius.only(
        topLeft: groupedTop ? groupedRadius : mainRadius,
        topRight: mainRadius,
        bottomLeft: groupedBottom ? groupedRadius : tailRadius,
        bottomRight: mainRadius,
      );
    }
  }

  EdgeInsets _getBubblePadding() {
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  }

  Widget _buildSenderName(ModernThemeExtension modernTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        widget.contact.name,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: modernTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildReplyPreview(bool isMyMessage, ModernThemeExtension modernTheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(isMyMessage ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: modernTheme.primaryColor ?? Colors.blue,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.message.repliedTo == widget.contact.uid 
                ? widget.contact.name 
                : 'You',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: modernTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.message.repliedMessage ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: isMyMessage ? Colors.white70 : modernTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(bool isMyMessage, ChatThemeExtension chatTheme) {
    switch (widget.message.messageType) {
      case MessageEnum.text:
        return _buildTextContent(isMyMessage);
      case MessageEnum.image:
        return _buildImageContent();
      case MessageEnum.video:
        return _buildVideoContent();
      case MessageEnum.audio:
        return _buildAudioContent(isMyMessage);
      case MessageEnum.file:
        return _buildFileContent(isMyMessage);
      default:
        return _buildTextContent(isMyMessage);
    }
  }

  Widget _buildTextContent(bool isMyMessage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.message.message,
          style: TextStyle(
            fontSize: 16,
            color: isMyMessage ? Colors.white : Colors.black87,
            height: 1.3,
          ),
        ),
        if (widget.message.isEdited)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'edited',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: isMyMessage ? Colors.white60 : Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageContent() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: widget.message.message,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(Icons.error, color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(12),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.black87,
              size: 32,
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Video',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioContent(bool isMyMessage) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isMyMessage ? Colors.white.withOpacity(0.2) : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.play_arrow,
              color: isMyMessage ? Colors.white : Colors.black87,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: isMyMessage ? Colors.white.withOpacity(0.3) : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: LinearProgressIndicator(
                    value: 0.3,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation(
                      isMyMessage ? Colors.white : Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '0:15',
                  style: TextStyle(
                    fontSize: 12,
                    color: isMyMessage ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileContent(bool isMyMessage) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isMyMessage ? Colors.white.withOpacity(0.2) : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.insert_drive_file,
              color: isMyMessage ? Colors.white : Colors.black87,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Document.pdf',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isMyMessage ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  '2.3 MB',
                  style: TextStyle(
                    fontSize: 12,
                    color: isMyMessage ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactions(ModernThemeExtension modernTheme) {
    final reactionCounts = <String, int>{};
    for (final reaction in widget.message.reactions.values) {
      final emoji = reaction['emoji'] ?? '👍';
      reactionCounts[emoji] = (reactionCounts[emoji] ?? 0) + 1;
    }

    return Container(
      margin: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: reactionCounts.entries.map((entry) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: modernTheme.dividerColor?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(entry.key, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  entry.value.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimestampAndStatus(bool isMyMessage, ChatThemeExtension chatTheme) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(
      int.parse(widget.message.timeSent),
    );
    final timeStr = DateFormat('HH:mm').format(dateTime);

    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            timeStr,
            style: TextStyle(
              fontSize: 11,
              color: isMyMessage ? Colors.white60 : Colors.grey[600],
            ),
          ),
          if (isMyMessage) ...[
            const SizedBox(width: 4),
            _buildMessageStatusIcon(),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageStatusIcon() {
    Color iconColor = Colors.white60;
    IconData iconData;

    switch (widget.message.messageStatus) {
      case MessageStatus.sending:
        iconData = Icons.access_time;
        break;
      case MessageStatus.sent:
        iconData = Icons.done;
        break;
      case MessageStatus.delivered:
        iconData = Icons.done_all;
        break;
      case MessageStatus.read:
        iconData = Icons.done_all;
        iconColor = Colors.lightBlueAccent;
        break;
      case MessageStatus.failed:
        iconData = Icons.error_outline;
        iconColor = Colors.redAccent;
        break;
    }

    return Icon(
      iconData,
      color: iconColor,
      size: 14,
    );
  }

  bool _shouldGroupWithPrevious() {
    if (widget.previousMessage == null) return false;
    
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return false;

    final isMyMessage = widget.message.senderUID == currentUser.uid;
    final previousIsMyMessage = widget.previousMessage!.senderUID == currentUser.uid;
    
    if (isMyMessage != previousIsMyMessage) return false;

    final currentTime = DateTime.fromMillisecondsSinceEpoch(int.parse(widget.message.timeSent));
    final previousTime = DateTime.fromMillisecondsSinceEpoch(int.parse(widget.previousMessage!.timeSent));
    
    return currentTime.difference(previousTime).inMinutes < 2;
  }

  bool _shouldGroupWithNext() {
    if (widget.nextMessage == null) return false;
    
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return false;

    final isMyMessage = widget.message.senderUID == currentUser.uid;
    final nextIsMyMessage = widget.nextMessage!.senderUID == currentUser.uid;
    
    if (isMyMessage != nextIsMyMessage) return false;

    final currentTime = DateTime.fromMillisecondsSinceEpoch(int.parse(widget.message.timeSent));
    final nextTime = DateTime.fromMillisecondsSinceEpoch(int.parse(widget.nextMessage!.timeSent));
    
    return nextTime.difference(currentTime).inMinutes < 2;
  }

  String _getAvatarInitials(String name) {
    if (name.isEmpty) return '?';
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}