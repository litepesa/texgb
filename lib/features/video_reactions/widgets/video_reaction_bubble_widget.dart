// lib/features/video_reactions/widgets/video_reaction_bubble_widget.dart
// COPIED: Exact same UI as chat version
import 'package:flutter/material.dart';
import 'package:textgb/features/video_reactions/models/video_reaction_model.dart';
import 'package:textgb/features/video_reactions/widgets/video_thumbnail_widget.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class VideoReactionBubbleWidget extends StatelessWidget {
  final VideoReactionModel videoReaction;
  final bool isCurrentUser;
  final VoidCallback? onVideoTap;
  final VoidCallback? onLongPress;

  const VideoReactionBubbleWidget({
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
                      fallbackThumbnailUrl: videoReaction.thumbnailUrl.isNotEmpty 
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
                    
                    // User info overlay
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
                                      ? videoReaction.userName[0].toUpperCase()
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
            if (videoReaction.reaction != null && videoReaction.reaction!.isNotEmpty) ...[
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