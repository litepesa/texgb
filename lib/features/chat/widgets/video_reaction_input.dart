// lib/features/chat/widgets/video_reaction_input.dart
import 'package:flutter/material.dart';
import 'package:textgb/features/channels/models/channel_video_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class VideoReactionInput extends StatefulWidget {
  final ChannelVideoModel video;
  final Function(String reaction) onSendReaction;
  final VoidCallback onCancel;

  const VideoReactionInput({
    super.key,
    required this.video,
    required this.onSendReaction,
    required this.onCancel,
  });

  @override
  State<VideoReactionInput> createState() => _VideoReactionInputState();
}

class _VideoReactionInputState extends State<VideoReactionInput> {
  final TextEditingController _textController = TextEditingController();
  final List<String> _quickReactions = ['❤️', '😍', '🔥', '😂', '👏', '💯', '🤩', '😮'];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _sendReaction(String reaction) {
    if (reaction.trim().isNotEmpty) {
      widget.onSendReaction(reaction);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Container(
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: modernTheme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Header
              Row(
                children: [
                  Text(
                    'React to video',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: modernTheme.textColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: widget.onCancel,
                    icon: Icon(
                      Icons.close,
                      color: modernTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Video preview
              Container(
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: modernTheme.surfaceVariantColor,
                ),
                child: Row(
                  children: [
                    // Video thumbnail
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      child: Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: widget.video.isMultipleImages && widget.video.imageUrls.isNotEmpty
                            ? Image.network(
                                widget.video.imageUrls.first,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) => Icon(
                                  Icons.video_library_outlined,
                                  color: modernTheme.textSecondaryColor,
                                ),
                              )
                            : widget.video.thumbnailUrl.isNotEmpty
                                ? Image.network(
                                    widget.video.thumbnailUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stack) => Icon(
                                      Icons.video_library_outlined,
                                      color: modernTheme.textSecondaryColor,
                                      size: 32,
                                    ),
                                  )
                                : Icon(
                                    Icons.video_library_outlined,
                                    color: modernTheme.textSecondaryColor,
                                    size: 32,
                                  ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Video info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: modernTheme.primaryColor?.withOpacity(0.2),
                                backgroundImage: widget.video.channelImage.isNotEmpty
                                    ? NetworkImage(widget.video.channelImage)
                                    : null,
                                child: widget.video.channelImage.isEmpty
                                    ? Text(
                                        widget.video.channelName.isNotEmpty 
                                          ? widget.video.channelName[0].toUpperCase()
                                          : 'C',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: modernTheme.primaryColor,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.video.channelName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: modernTheme.textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Video from channel',
                            style: TextStyle(
                              fontSize: 10,
                              color: modernTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Quick reactions
              Text(
                'Quick reactions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: modernTheme.textColor,
                ),
              ),
              const SizedBox(height: 12),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickReactions.map((emoji) {
                  return GestureDetector(
                    onTap: () => _sendReaction(emoji),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: modernTheme.primaryColor?.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: modernTheme.primaryColor?.withOpacity(0.3) ?? Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 20),
              
              // Text input
              Text(
                'Or write a message',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: modernTheme.textColor,
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      maxLines: 3,
                      minLines: 1,
                      style: TextStyle(color: modernTheme.textColor),
                      decoration: InputDecoration(
                        hintText: 'Type your reaction...',
                        hintStyle: TextStyle(color: modernTheme.textSecondaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: modernTheme.dividerColor!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: modernTheme.primaryColor!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: modernTheme.primaryColor,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: IconButton(
                      onPressed: () => _sendReaction(_textController.text),
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}