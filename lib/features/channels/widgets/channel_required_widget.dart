// lib/features/channels/widgets/channel_required_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/channels/screens/create_channel_screen.dart';

class ChannelRequiredWidget extends ConsumerWidget {
  final String title;
  final String subtitle;
  final String actionText;
  final IconData icon;

  const ChannelRequiredWidget({
    super.key,
    this.title = 'Channel Required',
    this.subtitle = 'You need to create a channel to perform this action.',
    this.actionText = 'Create Channel',
    this.icon = Icons.video_call,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modernTheme = context.modernTheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: modernTheme.primaryColor?.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: modernTheme.primaryColor,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: modernTheme.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: modernTheme.textSecondaryColor,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _navigateToCreateChannel(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: modernTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  actionText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: modernTheme.textSecondaryColor,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreateChannel(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateChannelScreen(),
      ),
    );
    
    // If channel was created successfully, pop this screen too
    if (result == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

// Utility function to check if user has channel and show dialog if not
Future<bool> requireUserChannel(
  BuildContext context,
  WidgetRef ref, {
  String? customTitle,
  String? customSubtitle,
  String? customActionText,
  IconData? customIcon,
}) async {
  final channelsState = ref.read(channelsProvider);
  
  if (channelsState.userChannel != null) {
    return true; // User has channel, proceed
  }
  
  // User doesn't have channel, show dialog
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: ChannelRequiredWidget(
          title: customTitle ?? 'Channel Required',
          subtitle: customSubtitle ?? 'You need to create a channel to upload content.',
          actionText: customActionText ?? 'Create Channel',
          icon: customIcon ?? Icons.video_call,
        ),
      ),
    ),
  );
  
  return result ?? false;
}

// Alternative: Inline widget for embedding in screens
class InlineChannelRequiredWidget extends ConsumerWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onCreateChannel;

  const InlineChannelRequiredWidget({
    super.key,
    this.title = 'Create Your Channel',
    this.subtitle = 'Start sharing your content by creating a channel.',
    this.onCreateChannel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modernTheme = context.modernTheme;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: modernTheme.primaryColor?.withOpacity(0.2) ?? Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.video_call,
            size: 48,
            color: modernTheme.primaryColor,
          ),
          
          const SizedBox(height: 16),
          
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: modernTheme.textColor,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: modernTheme.textSecondaryColor,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 20),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onCreateChannel ?? () => _navigateToCreateChannel(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Create Channel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateChannel(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateChannelScreen(),
      ),
    );
  }
}