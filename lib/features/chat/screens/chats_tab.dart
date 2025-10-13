// lib/features/chat/screens/chats_tab.dart
import 'package:flutter/material.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class ChatsTab extends StatelessWidget {
  const ChatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;

    return Container(
      color: modernTheme.surfaceColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: modernTheme.textSecondaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Chats',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: modernTheme.textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 16,
                color: modernTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}