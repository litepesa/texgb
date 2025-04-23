import 'package:flutter/material.dart';
import 'package:swipe_to/swipe_to.dart';
import 'package:textgb/models/message_model.dart';
import 'package:textgb/features/chat/widgets/align_message_left_widget.dart';
import 'package:textgb/features/chat/widgets/align_message_right_widget.dart';

class SwipeToWidget extends StatelessWidget {
  const SwipeToWidget({
    super.key,
    required this.onRightSwipe,
    required this.message,
    required this.isMe,
    required this.isGroupChat,
  });
  
  final Function() onRightSwipe;
  final MessageModel message;
  final bool isMe;
  final bool isGroupChat;
  
  @override
  Widget build(BuildContext context) {
    // Add a Container with constraints to fix layout issues
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
        minWidth: 100,
      ),
      child: SwipeTo(
        onRightSwipe: (details) {
          onRightSwipe();
        },
        child: isMe
            ? AlignMessageRightWidget(
                message: message,
                isGroupChat: isGroupChat,
              )
            : AlignMessageLeftWidget(
                message: message,
                isGroupChat: isGroupChat,
              ),
      ),
    );
  }
}