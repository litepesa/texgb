// lib/features/chat/widgets/swipe_to_wrapper.dart
import 'package:flutter/material.dart';
import 'package:swipe_to/swipe_to.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/features/chat/widgets/message_bubble.dart';

class SwipeToWrapper extends StatelessWidget {
  const SwipeToWrapper({
    super.key,
    required this.onRightSwipe,
    required this.message,
    required this.isCurrentUser,
    required this.isLastInGroup,
    required this.fontSize,
    required this.contactName,
    this.onLongPress,
    this.onVideoTap,
  });

  final VoidCallback onRightSwipe;
  final MessageModel message;
  final bool isCurrentUser;
  final bool isLastInGroup;
  final double fontSize;
  final String? contactName;
  final VoidCallback? onLongPress;
  final VoidCallback? onVideoTap;

  @override
  Widget build(BuildContext context) {
    return SwipeTo(
      onRightSwipe: (details) {
        onRightSwipe();
      },
      child: MessageBubble(
        message: message,
        isCurrentUser: isCurrentUser,
        isLastInGroup: isLastInGroup,
        fontSize: fontSize,
        contactName: contactName,
        onLongPress: onLongPress,
        onVideoTap: onVideoTap,
      ),
    );
  }
}
