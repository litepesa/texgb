import 'package:flutter/material.dart';
import 'package:textgb/models/message_model.dart';
import 'package:textgb/features/chat/widgets/swipe_to_widget.dart';

class MessageWidget extends StatelessWidget {
  const MessageWidget({
    super.key,
    required this.message,
    required this.onRightSwipe,
    required this.isMe,
    required this.isGroupChat,
  });

  final MessageModel message;
  final Function() onRightSwipe;
  final bool isMe;
  final bool isGroupChat;

  @override
  Widget build(BuildContext context) {
    // Add a SizedBox with width constraint to fix layout issues
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: SwipeToWidget(
        onRightSwipe: onRightSwipe,
        message: message,
        isMe: isMe,
        isGroupChat: isGroupChat,
      ),
    );
  }
}