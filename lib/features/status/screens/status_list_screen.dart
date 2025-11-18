// lib/features/status/screens/status_list_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class StatusListScreen extends ConsumerWidget {
  const StatusListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modernTheme = context.modernTheme;

    return Scaffold(
      backgroundColor: modernTheme.surfaceColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (modernTheme.primaryColor ?? const Color(0xFF07C160)).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.circle_filled,
                size: 64,
                color: modernTheme.primaryColor ?? const Color(0xFF07C160),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Status',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Status updates will appear here',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}