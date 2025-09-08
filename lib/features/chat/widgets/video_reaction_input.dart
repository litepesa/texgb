// lib/features/chat/widgets/video_reaction_input.dart - Refined version
import 'package:flutter/material.dart';
import 'package:textgb/features/chat/services/video_thumbnail_service.dart';
import 'package:textgb/features/chat/widgets/video_thumbnail_widget.dart';
import 'package:textgb/features/videos/models/video_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class VideoReactionInput extends StatefulWidget {
  final VideoModel video;
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
  final FocusNode _focusNode = FocusNode();
  final VideoThumbnailService _thumbnailService = VideoThumbnailService();

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendReaction(String reaction) {
    if (reaction.trim().isNotEmpty) {
      widget.onSendReaction(reaction);
      _textController.clear();
    }
  }

  // Get the best available thumbnail URL
  String? _getBestThumbnailUrl() {
    // Priority 1: Existing thumbnail URL
    if (widget.video.thumbnailUrl.isNotEmpty) {
      return widget.video.thumbnailUrl;
    }
    
    // Priority 2: First image from multiple images
    if (widget.video.isMultipleImages && widget.video.imageUrls.isNotEmpty) {
      return widget.video.imageUrls.first;
    }
    
    // Priority 3: Will generate from video URL (handled by VideoThumbnailWidget)
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.only(bottom: keyboardHeight),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            modernTheme.surfaceColor?.withOpacity(0.95) ?? Colors.white.withOpacity(0.95),
            modernTheme.surfaceColor ?? Colors.white,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: modernTheme.primaryColor?.withOpacity(0.05) ?? Colors.blue.withOpacity(0.05),
            blurRadius: 40,
            offset: const Offset(0, -8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar with modern design
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        modernTheme.primaryColor?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.3),
                        modernTheme.primaryColor?.withOpacity(0.6) ?? Colors.grey.withOpacity(0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Header with modern typography
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          modernTheme.primaryColor?.withOpacity(0.1) ?? Colors.blue.withOpacity(0.1),
                          modernTheme.primaryColor?.withOpacity(0.05) ?? Colors.blue.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: modernTheme.primaryColor?.withOpacity(0.2) ?? Colors.blue.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.videocam_rounded,
                          size: 16,
                          color: modernTheme.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'React to video',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: modernTheme.primaryColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: modernTheme.surfaceVariantColor?.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: modernTheme.dividerColor?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      onPressed: widget.onCancel,
                      icon: Icon(
                        Icons.close_rounded,
                        color: modernTheme.textSecondaryColor,
                        size: 20,
                      ),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Modern video preview card
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      modernTheme.surfaceVariantColor?.withOpacity(0.6) ?? Colors.grey.shade50,
                      modernTheme.surfaceVariantColor?.withOpacity(0.3) ?? Colors.grey.shade100,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: modernTheme.dividerColor?.withOpacity(0.5) ?? Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Enhanced video thumbnail
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 80,
                            height: 80,
                            child: VideoThumbnailWidget(
                              videoUrl: widget.video.videoUrl,
                              fallbackThumbnailUrl: _getBestThumbnailUrl(),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              showPlayButton: true,
                              enableGestures: false,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Enhanced video info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: modernTheme.primaryColor?.withOpacity(0.3) ?? Colors.blue.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: modernTheme.primaryColor?.withOpacity(0.1),
                                    backgroundImage: widget.video.userImage.isNotEmpty
                                        ? NetworkImage(widget.video.userImage)
                                        : null,
                                    child: widget.video.userImage.isEmpty
                                        ? Text(
                                            widget.video.userName.isNotEmpty 
                                              ? widget.video.userName[0].toUpperCase()
                                              : 'C',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: modernTheme.primaryColor,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.video.userName,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: modernTheme.textColor,
                                          letterSpacing: 0.1,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: modernTheme.primaryColor?.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Channel video',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w500,
                                            color: modernTheme.primaryColor,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 28),
              
              // Modern text input section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share your thoughts',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: modernTheme.textColor,
                        letterSpacing: -0.2,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Express what you think about this video',
                      style: TextStyle(
                        fontSize: 13,
                        color: modernTheme.textSecondaryColor?.withOpacity(0.8),
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Modern text input with enhanced design
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      modernTheme.surfaceColor ?? Colors.white,
                      modernTheme.surfaceVariantColor?.withOpacity(0.3) ?? Colors.grey.shade50,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: modernTheme.dividerColor?.withOpacity(0.6) ?? Colors.grey.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: modernTheme.primaryColor?.withOpacity(0.03) ?? Colors.blue.withOpacity(0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(
                          color: modernTheme.textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.1,
                          height: 1.4,
                        ),
                        decoration: InputDecoration(
                          hintText: 'What did you think about this video?',
                          hintStyle: TextStyle(
                            color: modernTheme.textSecondaryColor?.withOpacity(0.6),
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.1,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        onSubmitted: _sendReaction,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            modernTheme.primaryColor ?? Colors.blue,
                            modernTheme.primaryColor?.withOpacity(0.8) ?? Colors.blue.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: modernTheme.primaryColor?.withOpacity(0.3) ?? Colors.blue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _sendReaction(_textController.text),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Enhanced bottom padding with modern spacing
              SizedBox(height: keyboardHeight > 0 ? 12 : 24),
            ],
          ),
        ),
      ),
    );
  }
}