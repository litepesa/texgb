import 'package:flutter/material.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/widgets/audio_player_widget.dart';
import 'package:textgb/widgets/media_message_display.dart';

class DisplayMessageType extends StatelessWidget {
  const DisplayMessageType({
    super.key,
    required this.message,
    required this.type,
    required this.color,
    required this.isReply,
    this.maxLines,
    this.overFlow,
    required this.viewOnly,
    this.caption,
  });

  final String message;
  final MessageEnum type;
  final Color color;
  final bool isReply;
  final int? maxLines;
  final TextOverflow? overFlow;
  final bool viewOnly;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return messageToShow();
  }

  Widget messageToShow() {
    switch (type) {
      case MessageEnum.text:
        return Text(
          message,
          style: TextStyle(
            color: color,
            fontSize: isReply ? 13.0 : 16.0,
            height: 1.3,
          ),
          maxLines: maxLines,
          overflow: overFlow,
        );
        
      case MessageEnum.image:
        // For replies, show a simple icon
        if (isReply) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                'Photo',
                style: TextStyle(
                  color: color,
                  fontSize: 13.0,
                ),
              ),
            ],
          );
        }
        
        // Otherwise, show the image with our new media component
        return MediaMessageDisplay(
          mediaUrl: message,
          isImage: true,
          viewOnly: viewOnly,
          caption: caption,
        );
        
      case MessageEnum.video:
        // For replies, show a simple icon
        if (isReply) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                'Video',
                style: TextStyle(
                  color: color,
                  fontSize: 13.0,
                ),
              ),
            ],
          );
        }
        
        // Otherwise, show video preview with our new media component
        return MediaMessageDisplay(
          mediaUrl: message,
          isImage: false,
          viewOnly: viewOnly,
          caption: caption,
        );
        
      case MessageEnum.audio:
        // For replies, show a simple icon
        if (isReply) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.headphones, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                'Audio',
                style: TextStyle(
                  color: color,
                  fontSize: 13.0,
                ),
              ),
            ],
          );
        }
        
        // Otherwise, use the existing audio player widget
        return AudioPlayerWidget(
          audioUrl: message,
          color: color,
          viewOnly: viewOnly,
        );
        
      default:
        return Text(
          message,
          style: TextStyle(
            color: color,
            fontSize: 16.0,
          ),
          maxLines: maxLines,
          overflow: overFlow,
        );
    }
  }
}