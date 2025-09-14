// lib/features/chat/widgets/video_reaction_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
import 'package:textgb/features/chat/screens/chat_screen.dart';
import 'package:textgb/features/chat/models/video_reaction_model.dart';
import 'package:textgb/features/chat/widgets/video_reaction_input.dart';
import 'package:textgb/features/chat/repositories/chat_repository.dart';
import 'package:textgb/features/videos/models/video_model.dart';

class VideoReactionWidget extends ConsumerWidget {
  final Widget child;
  final String? label;
  final VideoModel? video;
  final VoidCallback? onPause;
  final VoidCallback? onResume;

  const VideoReactionWidget({
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
      // Get video owner's user data from usersProvider
      final users = ref.read(usersProvider);
      final videoOwner = users.firstWhere(
        (user) => user.uid == video!.userId,
        orElse: () => throw Exception('Video owner not found'),
      );

      // Show reaction input bottom sheet
      final reaction = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => VideoReactionInput(
          video: video!,
          onSendReaction: (reaction) => Navigator.pop(context, reaction),
          onCancel: () => Navigator.pop(context),
        ),
      );

      // If reaction was provided, create chat and send reaction
      if (reaction != null && reaction.trim().isNotEmpty && context.mounted) {
        final chatListNotifier = ref.read(chatListProvider.notifier);
        final chatId = await chatListNotifier.createOrGetChat(currentUser.uid, videoOwner.uid);
        
        if (chatId != null) {
          // Send video reaction message
          await _sendVideoReactionMessage(
            ref: ref,
            chatId: chatId,
            video: video!,
            reaction: reaction,
            senderId: currentUser.uid,
          );

          // Navigate to chat to show the sent reaction
          if (context.mounted) {
            await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  chatId: chatId,
                  contact: videoOwner,
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error creating video reaction: $e');
      if (context.mounted) {
        _showSnackBar(context, 'Failed to send reaction');
      }
    } finally {
      // Resume video if callback provided
      onResume?.call();
    }
  }

  // Helper method to send video reaction message
  Future<void> _sendVideoReactionMessage({
    required WidgetRef ref,
    required String chatId,
    required VideoModel video,
    required String reaction,
    required String senderId,
  }) async {
    try {
      final chatRepository = ref.read(chatRepositoryProvider);
      
      // Create video reaction data
      final videoReaction = VideoReactionModel(
        videoId: video.id,
        videoUrl: video.videoUrl,
        thumbnailUrl: video.isMultipleImages && video.imageUrls.isNotEmpty 
            ? video.imageUrls.first 
            : video.thumbnailUrl,
        channelName: video.userName, // Use userName for video creator
        channelImage: video.userImage, // Use userImage for video creator
        reaction: reaction,
        timestamp: DateTime.now(),
      );

      // Send as a video reaction message
      await chatRepository.sendVideoReactionMessage(
        chatId: chatId,
        senderId: senderId,
        videoReaction: videoReaction,
      );
      
    } catch (e) {
      debugPrint('Error sending video reaction message: $e');
      rethrow;
    }
  }

  // Helper method to show cannot react to own video message
  void _showCannotReactToOwnVideoMessage(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.info_outline,
              color: Colors.orange,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Cannot React to Your Own Video',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You cannot send reactions to your own videos.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Got it'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to show snackbar
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}