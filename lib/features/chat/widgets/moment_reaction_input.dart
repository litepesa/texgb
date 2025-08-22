// lib/features/chat/widgets/moment_reaction_input.dart - Following channel feed design language
import 'package:flutter/material.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:video_player/video_player.dart';

class MomentReactionInput extends StatefulWidget {
  final MomentModel moment;
  final Function(String reaction) onSendReaction;
  final VoidCallback onCancel;

  const MomentReactionInput({
    super.key,
    required this.moment,
    required this.onSendReaction,
    required this.onCancel,
  });

  @override
  State<MomentReactionInput> createState() => _MomentReactionInputState();
}

class _MomentReactionInputState extends State<MomentReactionInput> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPreview();
  }

  Future<void> _initializeVideoPreview() async {
    if (widget.moment.hasVideo && widget.moment.videoUrl != null) {
      try {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(widget.moment.videoUrl!),
        );
        await _videoController!.initialize();
        _videoController!.setLooping(true);
        _videoController!.setVolume(0); // Muted preview
        _videoController!.play();
        
        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
          });
        }
      } catch (e) {
        debugPrint('Error initializing video preview: $e');
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _sendReaction(String reaction) {
    if (reaction.trim().isNotEmpty) {
      widget.onSendReaction(reaction);
      _textController.clear();
    }
  }

  Widget _buildMomentPreview() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.modernTheme.surfaceVariantColor?.withOpacity(0.6) ?? Colors.grey.shade50,
            context.modernTheme.surfaceVariantColor?.withOpacity(0.3) ?? Colors.grey.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.modernTheme.dividerColor?.withOpacity(0.5) ?? Colors.grey.withOpacity(0.2),
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
            // Moment media preview
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
                  child: _buildMediaPreview(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Moment info
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
                            color: context.modernTheme.primaryColor?.withOpacity(0.3) ?? Colors.blue.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: context.modernTheme.primaryColor?.withOpacity(0.1),
                          backgroundImage: widget.moment.authorImage.isNotEmpty
                              ? NetworkImage(widget.moment.authorImage)
                              : null,
                          child: widget.moment.authorImage.isEmpty
                              ? Text(
                                  widget.moment.authorName.isNotEmpty 
                                    ? widget.moment.authorName[0].toUpperCase()
                                    : 'U',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: context.modernTheme.primaryColor,
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
                              widget.moment.authorName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: context.modernTheme.textColor,
                                letterSpacing: 0.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: context.modernTheme.primaryColor?.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.moment.hasVideo ? 'Video moment' : 'Photo moment',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: context.modernTheme.primaryColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Show moment content if available
                  if (widget.moment.content.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.moment.content,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.modernTheme.textSecondaryColor?.withOpacity(0.8),
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview() {
    if (widget.moment.hasVideo) {
      if (_isVideoInitialized && _videoController != null) {
        return Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: VideoPlayer(_videoController!),
              ),
            ),
            // Play icon overlay
            Center(
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        );
      } else {
        return Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
        );
      }
    } else if (widget.moment.hasImages) {
      return Image.network(
        widget.moment.imageUrls.first,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey.shade200,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade300,
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.grey),
            ),
          );
        },
      );
    } else {
      return Container(
        color: context.modernTheme.primaryColor?.withOpacity(0.1),
        child: Center(
          child: Icon(
            Icons.text_snippet,
            color: context.modernTheme.primaryColor,
            size: 32,
          ),
        ),
      );
    }
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
              // Handle bar
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
              
              // Header
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
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: modernTheme.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'React to moment',
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
              
              // Moment preview
              _buildMomentPreview(),
              
              const SizedBox(height: 28),
              
              // Text input section header
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
                      'Express what you think about this moment',
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
              
              // Text input
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
                          hintText: 'What did you think about this moment?',
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
              
              SizedBox(height: keyboardHeight > 0 ? 12 : 24),
            ],
          ),
        ),
      ),
    );
  }
}