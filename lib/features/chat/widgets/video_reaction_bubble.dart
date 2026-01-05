// lib/features/chat/widgets/video_reaction_bubble.dart
// UPDATED: Changed channel references to user references for users-based system
import 'package:flutter/material.dart';
import 'package:textgb/features/chat/models/video_reaction_model.dart';
import 'package:textgb/features/chat/repositories/chat_repository.dart';
import 'package:textgb/features/chat/services/video_thumbnail_service.dart';
import 'package:textgb/features/chat/widgets/video_thumbnail_widget.dart';
import 'package:textgb/features/videos/models/video_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class VideoReactionBubble extends StatelessWidget {
  final VideoReactionModel videoReaction;
  final bool isCurrentUser;
  final VoidCallback? onVideoTap;
  final VoidCallback? onLongPress;

  const VideoReactionBubble({
    super.key,
    required this.videoReaction,
    required this.isCurrentUser,
    this.onVideoTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final chatTheme = context.chatTheme;

    return GestureDetector(
      onTap: onVideoTap,
      onLongPress: onLongPress,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? chatTheme.senderBubbleColor
              : chatTheme.receiverBubbleColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video thumbnail section with smart thumbnail generation
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Smart video thumbnail with auto-generation fallback
                    VideoThumbnailWidget(
                      videoUrl: videoReaction.videoUrl,
                      fallbackThumbnailUrl:
                          videoReaction.thumbnailUrl.isNotEmpty
                              ? videoReaction.thumbnailUrl
                              : null,
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                      showPlayButton: false,
                      enableGestures: false,
                      borderRadius: BorderRadius.zero,
                    ),

                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),

                    // Play button
                    Center(
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),

                    // User info overlay (changed from channel info)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.white,
                            backgroundImage: videoReaction.userImage.isNotEmpty
                                ? NetworkImage(videoReaction.userImage)
                                : null,
                            child: videoReaction.userImage.isEmpty
                                ? Text(
                                    videoReaction.userName.isNotEmpty
                                        ? videoReaction.userName[0]
                                            .toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              videoReaction.userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(
                                    color: Colors.black,
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Reaction section (if present)
            if (videoReaction.reaction != null &&
                videoReaction.reaction!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  videoReaction.reaction!,
                  style: TextStyle(
                    fontSize: 16,
                    color: isCurrentUser
                        ? chatTheme.senderTextColor
                        : chatTheme.receiverTextColor,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

// Updated helper method with users-based field names
Future<void> sendVideoReactionMessage({
  required String chatId,
  required VideoModel video,
  required String reaction,
  required String senderId,
  required ChatRepository chatRepository,
  VideoThumbnailService? thumbnailService,
}) async {
  try {
    final thumbnailSvc = thumbnailService ?? VideoThumbnailService();

    // Get or generate the best available thumbnail
    String thumbnailUrl = '';

    // Priority 1: Use existing thumbnail
    if (video.thumbnailUrl.isNotEmpty) {
      thumbnailUrl = video.thumbnailUrl;
    }
    // Priority 2: Use first image if it's a multiple images post
    else if (video.isMultipleImages && video.imageUrls.isNotEmpty) {
      thumbnailUrl = video.imageUrls.first;
    }
    // Priority 3: Generate thumbnail from video URL
    else if (video.videoUrl.isNotEmpty) {
      debugPrint('Generating thumbnail for video reaction: ${video.videoUrl}');
      try {
        final generatedThumbnail =
            await thumbnailSvc.generateThumbnail(video.videoUrl);
        if (generatedThumbnail != null) {
          thumbnailUrl = generatedThumbnail; // This will be a local file path
          debugPrint('Generated thumbnail: $thumbnailUrl');
        }
      } catch (e) {
        debugPrint('Failed to generate thumbnail: $e');
        // Continue without thumbnail - the VideoThumbnailWidget will handle generation in UI
      }
    }

    // Create video reaction data with user-based field names
    final videoReaction = VideoReactionModel(
      videoId: video.id,
      videoUrl: video.videoUrl,
      thumbnailUrl:
          thumbnailUrl, // Will be generated URL, existing URL, or empty
      userName: video.userName, // Changed from channelName
      userImage: video.userImage, // Changed from channelImage
      reaction: reaction,
      timestamp: DateTime.now(),
    );

    // Send as a video reaction message
    await chatRepository.sendVideoReactionMessage(
      chatId: chatId,
      senderId: senderId,
      videoReaction: videoReaction,
    );

    debugPrint('Video reaction sent successfully to chat: $chatId');
  } catch (e) {
    debugPrint('Error sending video reaction message: $e');
    rethrow;
  }
}
