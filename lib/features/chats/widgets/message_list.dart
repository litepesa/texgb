import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';
import 'package:textgb/features/chats/models/chat_message_model.dart';
import 'package:textgb/features/chats/widgets/message_bubble.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class MessageList extends ConsumerStatefulWidget {
  final List<ChatMessageModel> messages;
  final Function(ChatMessageModel) onReplyMessage;

  const MessageList({
    Key? key,
    required this.messages,
    required this.onReplyMessage,
  }) : super(key: key);

  @override
  ConsumerState<MessageList> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<MessageList> {
  late ScrollController _scrollController;
  bool _isScrollToBottomVisible = false;
  double _lastScrollPosition = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      // Show scroll to bottom button if not at bottom
      final isNotAtBottom = _scrollController.position.pixels < _scrollController.position.maxScrollExtent - 200;
      
      if (isNotAtBottom != _isScrollToBottomVisible) {
        setState(() {
          _isScrollToBottomVisible = isNotAtBottom;
        });
      }
      
      _lastScrollPosition = _scrollController.position.pixels;
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

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    if (widget.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 70,
              color: modernTheme.textSecondaryColor?.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: modernTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start the conversation',
              style: TextStyle(
                fontSize: 14,
                color: modernTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        GroupedListView<ChatMessageModel, String>(
          elements: widget.messages,
          reverse: true,
          controller: _scrollController,
          groupBy: (message) => _getGroupDate(message.timeSent),
          order: GroupedListOrder.DESC,
          floatingHeader: true,
          useStickyGroupSeparators: true,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
          groupHeaderBuilder: (ChatMessageModel message) => _buildDateHeader(message.timeSent),
          itemBuilder: (context, ChatMessageModel message) {
            return MessageBubble(
              message: message,
              onReplyTap: () => widget.onReplyMessage(message),
            );
          },
          separator: const SizedBox(height: 2),
        ),
        
        // Scroll to bottom button
        if (_isScrollToBottomVisible)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: modernTheme.surfaceColor,
              onPressed: _scrollToBottom,
              elevation: 3,
              child: Icon(
                Icons.keyboard_arrow_down,
                color: modernTheme.primaryColor,
              ),
            ),
          ),
      ],
    );
  }

  String _getGroupDate(int timestamp) {
    final messageDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDay = DateTime(messageDate.year, messageDate.month, messageDate.day);

    if (messageDay == today) {
      return 'Today';
    } else if (messageDay == yesterday) {
      return 'Yesterday';
    } else {
      // Check if it's in the current week
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      if (messageDay.isAfter(weekStart) || messageDay.isAtSameMomentAs(weekStart)) {
        return DateFormat('EEEE').format(messageDate); // Day name (Monday, Tuesday, etc.)
      } else if (messageDay.year == now.year) {
        return DateFormat('MMMM d').format(messageDate); // Month day (January 4, February 22, etc.)
      } else {
        return DateFormat('MMM d, y').format(messageDate); // Full date for previous years
      }
    }
  }

  Widget _buildDateHeader(int timestamp) {
    final modernTheme = context.modernTheme;
    final dateString = _getGroupDate(timestamp);
    
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: modernTheme.surfaceColor?.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: modernTheme.dividerColor ?? Colors.grey.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Text(
          dateString,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: modernTheme.textSecondaryColor,
          ),
        ),
      ),
    );
  }
}