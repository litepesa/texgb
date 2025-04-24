import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/main_screen/media_viewer_screen.dart';

class MediaMessageDisplay extends StatelessWidget {
  final String mediaUrl;
  final bool isImage;
  final bool viewOnly;
  final double maxWidth;
  final double maxHeight;
  final String? caption;
  
  const MediaMessageDisplay({
    Key? key,
    required this.mediaUrl,
    required this.isImage,
    this.viewOnly = false,
    this.maxWidth = 220,
    this.maxHeight = 200,
    this.caption,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: viewOnly 
          ? null 
          : () => _openMediaViewer(context),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.responsiveTheme.compactRadius / 2),
          child: isImage
              ? _buildImagePreview(context)
              : _buildVideoPreview(context),
        ),
      ),
    );
  }
  
  Widget _buildImagePreview(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Stack(
      children: [
        // Image
        CachedNetworkImage(
          imageUrl: mediaUrl,
          fit: BoxFit.cover,
          width: maxWidth,
          height: isSquareImage() ? maxWidth : null,
          placeholder: (context, url) => Container(
            width: maxWidth,
            height: maxWidth * 0.75,
            color: modernTheme.surfaceVariantColor,
            child: Center(
              child: CircularProgressIndicator(
                color: modernTheme.primaryColor,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: maxWidth,
            height: maxWidth * 0.75,
            color: modernTheme.surfaceVariantColor,
            child: Center(
              child: Icon(
                Icons.error,
                color: modernTheme.textSecondaryColor,
              ),
            ),
          ),
        ),
        
        // Caption if provided
        if (caption != null && caption!.isNotEmpty)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: context.responsiveTheme.compactSpacing * 0.75,
                horizontal: context.responsiveTheme.compactSpacing * 1.25,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
              child: Text(
                caption!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildVideoPreview(BuildContext context) {
    final modernTheme = context.modernTheme;
    final animationTheme = context.animationTheme;
    
    return Stack(
      children: [
        // Video thumbnail
        Container(
          width: maxWidth,
          height: maxWidth * 0.75,
          color: modernTheme.surfaceVariantColor,
          child: CachedNetworkImage(
            imageUrl: mediaUrl + '?thumbnail=true', // Assuming thumbnail URL can be derived
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: modernTheme.surfaceVariantColor,
              child: Center(
                child: CircularProgressIndicator(
                  color: modernTheme.primaryColor,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Center(
              child: Icon(
                Icons.video_library,
                color: modernTheme.textColor,
                size: 40,
              ),
            ),
          ),
        ),
        
        // Play button overlay
        Positioned.fill(
          child: Center(
            child: AnimatedContainer(
              duration: animationTheme.shortDuration,
              curve: animationTheme.standardCurve,
              padding: EdgeInsets.all(context.responsiveTheme.compactSpacing * 1.5),
              decoration: BoxDecoration(
                color: modernTheme.primaryColor?.withOpacity(0.7) ?? Colors.black.withOpacity(0.5),
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
        
        // Video duration indicator
        Positioned(
          right: context.responsiveTheme.compactSpacing,
          bottom: context.responsiveTheme.compactSpacing,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.responsiveTheme.compactSpacing * 0.75,
              vertical: context.responsiveTheme.compactSpacing * 0.25,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(context.responsiveTheme.compactRadius / 2),
            ),
            child: const Text(
              "Video",  // Ideally we'd show the duration here
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  bool isSquareImage() {
    // In practice, we would check the actual image dimensions
    // For now, we're just assuming a default aspect ratio
    return false;
  }
  
  void _openMediaViewer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaViewerScreen(
          mediaUrl: mediaUrl,
          isImage: isImage,
          caption: caption,
        ),
      ),
    );
  }
}