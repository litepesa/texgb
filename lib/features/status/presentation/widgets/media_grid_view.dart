import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter/services.dart';

class MediaGridView extends StatelessWidget {
  final List<AssetEntity> mediaItems;
  final Function(AssetEntity) onTap;
  final int crossAxisCount;
  
  const MediaGridView({
    Key? key,
    required this.mediaItems,
    required this.onTap,
    this.crossAxisCount = 3,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: mediaItems.length,
      itemBuilder: (context, index) {
        final asset = mediaItems[index];
        return _MediaThumbnail(
          asset: asset,
          onTap: () => onTap(asset),
        );
      },
    );
  }
}

class _MediaThumbnail extends StatelessWidget {
  final AssetEntity asset;
  final VoidCallback onTap;
  
  const _MediaThumbnail({
    Key? key,
    required this.asset,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail
          FutureBuilder<Uint8List?>(
            future: asset.thumbnailData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                return Image.memory(
                  snapshot.data!,
                  fit: BoxFit.cover,
                );
              }
              return Container(
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              );
            },
          ),
          
          // Type and duration indicators
          if (asset.type == AssetType.video)
            Positioned(
              right: 5,
              bottom: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      _formatDuration(asset.duration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}