// lib/features/chat/widgets/video_reaction_bubble.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/chat/models/video_reaction_model.dart';
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
            // Video thumbnail section
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Container(
                height: 160,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Video thumbnail
                    CachedNetworkImage(
                      imageUrl: videoReaction.thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: modernTheme.surfaceVariantColor,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: modernTheme.primaryColor,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: modernTheme.surfaceVariantColor,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.video_library_outlined,
                              color: modernTheme.textSecondaryColor,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Video',
                              style: TextStyle(
                                color: modernTheme.textSecondaryColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                    
                    // Channel info overlay
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.white,
                            backgroundImage: videoReaction.channelImage.isNotEmpty
                                ? CachedNetworkImageProvider(videoReaction.channelImage)
                                : null,
                            child: videoReaction.channelImage.isEmpty
                                ? Text(
                                    videoReaction.channelName.isNotEmpty 
                                      ? videoReaction.channelName[0].toUpperCase()
                                      : 'C',
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
                              videoReaction.channelName,
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