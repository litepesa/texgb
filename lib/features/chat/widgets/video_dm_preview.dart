// lib/features/chat/widgets/video_dm_preview.dart
import 'package:flutter/material.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/features/chat/widgets/video_thumbnail_widget.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class VideoDMPreview extends StatelessWidget {
  final MessageModel videoMessage;
  final String? contactName;
  final VoidCallback? onCancel;
  final VoidCallback? onVideoTap;

  const VideoDMPreview({
    super.key,
    required this.videoMessage,
    this.contactName,
    this.onCancel,
    this.onVideoTap,
  });

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: modernTheme.primaryColor?.withOpacity(0.1) ??
            Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: modernTheme.primaryColor?.withOpacity(0.3) ??
              Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Blue vertical line indicator
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: modernTheme.primaryColor ?? Colors.blue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            // Video thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 60,
                height: 80,
                child: Stack(
                  children: [
                    // Video thumbnail
                    VideoThumbnailWidget(
                      videoUrl: videoMessage.mediaUrl ?? '',
                      fallbackThumbnailUrl: videoMessage
                          .mediaMetadata?['thumbnailUrl'] as String?,
                      width: 60,
                      height: 80,
                      borderRadius: BorderRadius.circular(8),
                      fit: BoxFit.cover,
                      showPlayButton: false, // We'll add our own
                      enableGestures: false, // Disable default gestures
                    ),

                    // Custom play button overlay with tap handling
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: onVideoTap,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment.center,
                                radius: 0.6,
                                colors: [
                                  Colors.black.withOpacity(0.3),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Content info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title
                  Row(
                    children: [
                      Icon(
                        Icons.videocam,
                        size: 16,
                        color: modernTheme.primaryColor ?? Colors.blue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Sharing video',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: modernTheme.primaryColor ?? Colors.blue,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Description
                  Text(
                    'Video will be sent to ${contactName ?? 'contact'}',
                    style: TextStyle(
                      color: modernTheme.textColor?.withOpacity(0.7) ??
                          Colors.black.withOpacity(0.7),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Video info if available
                  if (videoMessage.content.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      videoMessage.content,
                      style: TextStyle(
                        color: modernTheme.textColor?.withOpacity(0.6) ??
                            Colors.black.withOpacity(0.6),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Close button
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onCancel,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: modernTheme.textColor?.withOpacity(0.1) ??
                        Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: modernTheme.textColor?.withOpacity(0.3) ??
                          Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: modernTheme.textColor?.withOpacity(0.8) ??
                        Colors.black.withOpacity(0.8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
