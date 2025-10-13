// lib/features/groups/screens/groups_tab.dart
import 'package:flutter/material.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class GroupsTab extends StatelessWidget {
  const GroupsTab({super.key});

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
              Icons.group_outlined,
              size: 80,
              color: modernTheme.textSecondaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Groups',
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