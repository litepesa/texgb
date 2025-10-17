// lib/features/video_reactions/widgets/video_reaction_action_widget.dart
// NEW: Main action widget to trigger video reactions
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/video_reactions/providers/video_reactions_provider.dart';
import 'package:textgb/features/video_reactions/screens/video_reaction_chat_screen.dart';
import 'package:textgb/features/video_reactions/widgets/video_reaction_input_widget.dart';
import 'package:textgb/features/videos/models/video_model.dart';

class VideoReactionActionWidget extends ConsumerWidget {
  final Widget child;
  final String? label;
  final VideoModel? video;
  final VoidCallback? onPause;
  final VoidCallback? onResume;

  const VideoReactionActionWidget({
    super.key,
    required this.child,
    this.label,
    required this.video,
    this.onPause,
    this.onResume,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _handleVideoReaction(context, ref),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            child: child,
          ),
          if (label != null) ...[
            const SizedBox(height: 2),
            Text(
              label!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleVideoReaction(BuildContext context, WidgetRef ref) async {
    if (video == null) {
      debugPrint('No video available for reaction');
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      debugPrint('User not authenticated');
      return;
    }

    // Check if user is trying to react to their own video
    if (video!.userId == currentUser.uid) {
      _showCannotReactToOwnVideoMessage(context);
      return;
    }

    // Pause video if callback provided
    onPause?.call();

    try {
      // Get video owner's user data using authentication provider
      final authNotifier = ref.read(authenticationProvider.notifier);
      final videoOwner = await authNotifier.getUserById(video!.userId);
      
      if (videoOwner == null) {
        throw Exception('Video owner not found');
      }

      // Show reaction input bottom sheet
      final reaction = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => VideoReactionInputWidget(
          video: video!,
          onSendReaction: (reaction) => Navigator.pop(context, reaction),
          onCancel: () => Navigator.pop(context),
        ),
      );

      // If reaction was provided, create chat and send reaction
      if (reaction != null && reaction.trim().isNotEmpty && context.mounted) {
        final chatListNotifier = ref.read(videoReactionChatsListProvider.notifier);
        final chatId = await chatListNotifier.createVideoReactionFromVideo(
          video: video!,
          reaction: reaction,
        );
        
        if (chatId != null) {
          // Navigate to video reaction chat to show the sent reaction
          if (context.mounted) {
            await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (context) => VideoReactionChatScreen(
                  chatId: chatId,
                  contact: videoOwner,
                ),
              ),
            );
          }
        } else {
          throw Exception('Failed to create video reaction chat');
        }
      }
    } catch (e) {
      debugPrint('Error creating video reaction: $e');
      if (context.mounted) {
        _showSnackBar(context, 'Failed to send reaction: ${e.toString()}');
      }
    } finally {
      // Resume video if callback provided
      onResume?.call();
    }
  }

  // Helper method to show cannot react to own video message
  void _showCannotReactToOwnVideoMessage(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.info_outline,
                color: Colors.orange,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Cannot React to Your Own Video',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'You cannot send reactions to videos that you created. Try reacting to other users\' videos instead!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to show snackbar with better styling
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Static method to create a video reaction widget with common styling
  static Widget createReactionButton({
    required VideoModel video,
    VoidCallback? onPause,
    VoidCallback? onResume,
    IconData icon = Icons.chat_bubble_outline,
    String? label,
    Color iconColor = Colors.white,
    double iconSize = 24,
  }) {
    return VideoReactionActionWidget(
      video: video,
      onPause: onPause,
      onResume: onResume,
      label: label,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: iconSize,
        ),
      ),
    );
  }

  // Static method to create a floating action button for video reactions
  static Widget createFloatingReactionButton({
    required VideoModel video,
    VoidCallback? onPause,
    VoidCallback? onResume,
    String label = 'React',
  }) {
    return VideoReactionActionWidget(
      video: video,
      onPause: onPause,
      onResume: onResume,
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.withOpacity(0.8),
              Colors.pink.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: Colors.white,
              size: 18,
            ),
            SizedBox(width: 6),
            Text(
              'React',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}