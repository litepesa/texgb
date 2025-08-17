// lib/features/chat/widgets/video_thumbnail_widget.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/chat/services/video_thumbnail_service.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class VideoThumbnailWidget extends StatefulWidget {
  final String videoUrl;
  final String? fallbackThumbnailUrl; // Network thumbnail URL as fallback
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool showPlayButton;
  final Widget? overlayWidget;
  final BoxFit fit;

  const VideoThumbnailWidget({
    super.key,
    required this.videoUrl,
    this.fallbackThumbnailUrl,
    this.width = double.infinity,
    this.height = 180,
    this.borderRadius,
    this.onTap,
    this.showPlayButton = true,
    this.overlayWidget,
    this.fit = BoxFit.cover,
  });

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  final VideoThumbnailService _thumbnailService = VideoThumbnailService();
  
  String? _generatedThumbnailPath;
  Uint8List? _thumbnailData;
  bool _isGenerating = false;
  bool _generationFailed = false;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  @override
  void didUpdateWidget(VideoThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Regenerate thumbnail if video URL changed
    if (oldWidget.videoUrl != widget.videoUrl) {
      _generateThumbnail();
    }
  }

  Future<void> _generateThumbnail() async {
    if (!_thumbnailService.isValidVideoUrl(widget.videoUrl)) {
      setState(() {
        _generationFailed = true;
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _generationFailed = false;
      _generatedThumbnailPath = null;
      _thumbnailData = null;
    });

    try {
      // Try to generate thumbnail file first (better for caching)
      final thumbnailPath = await _thumbnailService.generateThumbnail(widget.videoUrl);
      
      if (thumbnailPath != null && mounted) {
        setState(() {
          _generatedThumbnailPath = thumbnailPath;
          _isGenerating = false;
        });
        return;
      }

      // If file generation failed, try data generation
      final thumbnailData = await _thumbnailService.generateThumbnailData(widget.videoUrl);
      
      if (thumbnailData != null && mounted) {
        setState(() {
          _thumbnailData = thumbnailData;
          _isGenerating = false;
        });
        return;
      }

      // Both methods failed
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _generationFailed = true;
        });
      }
    } catch (e) {
      debugPrint('Error in thumbnail generation: $e');
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _generationFailed = true;
        });
      }
    }
  }

  Widget _buildThumbnailContent(ModernThemeExtension modernTheme) {
    // Priority 1: Generated thumbnail file
    if (_generatedThumbnailPath != null) {
      return Image.file(
        File(_generatedThumbnailPath!),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
          return _buildFallbackThumbnail(modernTheme);
        },
      );
    }

    // Priority 2: Generated thumbnail data
    if (_thumbnailData != null) {
      return Image.memory(
        _thumbnailData!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
          return _buildFallbackThumbnail(modernTheme);
        },
      );
    }

    // Priority 3: Fallback network thumbnail
    if (!_generationFailed && widget.fallbackThumbnailUrl != null && widget.fallbackThumbnailUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.fallbackThumbnailUrl!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: (BuildContext context, String url) => _buildLoadingPlaceholder(modernTheme),
        errorWidget: (BuildContext context, String url, dynamic error) => _buildErrorPlaceholder(modernTheme),
      );
    }

    // Priority 4: Loading or error state
    if (_isGenerating) {
      return _buildLoadingPlaceholder(modernTheme);
    } else {
      return _buildErrorPlaceholder(modernTheme);
    }
  }

  Widget _buildFallbackThumbnail(ModernThemeExtension modernTheme) {
    // Try fallback network thumbnail if available
    if (widget.fallbackThumbnailUrl != null && widget.fallbackThumbnailUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.fallbackThumbnailUrl!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: (BuildContext context, String url) => _buildErrorPlaceholder(modernTheme),
        errorWidget: (BuildContext context, String url, dynamic error) => _buildErrorPlaceholder(modernTheme),
      );
    }
    
    return _buildErrorPlaceholder(modernTheme);
  }

  Widget _buildLoadingPlaceholder(ModernThemeExtension modernTheme) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: modernTheme.surfaceVariantColor?.withOpacity(0.3) ?? Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: modernTheme.primaryColor,
            strokeWidth: 2,
          ),
          const SizedBox(height: 8),
          Text(
            'Generating thumbnail...',
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPlaceholder(ModernThemeExtension modernTheme) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: modernTheme.surfaceVariantColor?.withOpacity(0.3) ?? Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            color: modernTheme.textSecondaryColor,
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            'Video Preview',
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_generationFailed) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: _generateThumbnail,
              child: Text(
                'Tap to retry',
                style: TextStyle(
                  color: modernTheme.primaryColor,
                  fontSize: 10,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail content
              _buildThumbnailContent(modernTheme),
              
              // Play button overlay
              if (widget.showPlayButton && !_isGenerating) ...[
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.center,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ],
              
              // Custom overlay widget
              if (widget.overlayWidget != null) widget.overlayWidget!,
            ],
          ),
        ),
      ),
    );
  }
}