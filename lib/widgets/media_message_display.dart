import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';
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
    // Get theme colors
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    final greyColor = themeExtension?.greyColor ?? Colors.grey;
    
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
          borderRadius: BorderRadius.circular(4.0),
          child: isImage
              ? _buildImagePreview(context, greyColor)
              : _buildVideoPreview(context, greyColor),
        ),
      ),
    );
  }
  
  Widget _buildImagePreview(BuildContext context, Color greyColor) {
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
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: maxWidth,
            height: maxWidth * 0.75,
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.error),
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
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
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
  
  Widget _buildVideoPreview(BuildContext context, Color greyColor) {
    return Stack(
      children: [
        // Video thumbnail (placeholder in this case)
        Container(
          width: maxWidth,
          height: maxWidth * 0.75,
          color: Colors.grey[800],
          child: CachedNetworkImage(
            imageUrl: mediaUrl + '?thumbnail=true', // Assuming thumbnail URL can be derived
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[800],
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
            errorWidget: (context, url, error) => const Center(
              child: Icon(
                Icons.video_library,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ),
        
        // Play button overlay
        Positioned.fill(
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
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
        
        // Video duration (we'd need to get this from the actual video)
        Positioned(
          right: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
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