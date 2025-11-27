// lib/features/groups/widgets/group_typing_indicator.dart
import 'package:flutter/material.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class GroupTypingIndicator extends StatelessWidget {
  final String typingText;

  const GroupTypingIndicator({
    super.key,
    required this.typingText,
  });

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildDots(modernTheme),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              typingText,
              style: TextStyle(
                fontSize: 13,
                color: modernTheme.textSecondaryColor,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDots(ModernThemeExtension theme) {
    return Row(
      children: [
        _buildDot(0, theme),
        const SizedBox(width: 4),
        _buildDot(1, theme),
        const SizedBox(width: 4),
        _buildDot(2, theme),
      ],
    );
  }

  Widget _buildDot(int index, ModernThemeExtension theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 100)),
      builder: (context, value, child) {
        return Opacity(
          opacity: (value * 2).clamp(0.0, 1.0),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: theme.textSecondaryColor,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
