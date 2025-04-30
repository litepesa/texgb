import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../domain/models/status_media.dart';

class StatusMediaViewer extends StatefulWidget {
  final List<StatusMedia> mediaItems;
  final int initialIndex;
  final bool autoPlayVideos;
  
  const StatusMediaViewer({
    Key? key,
    required this.mediaItems,
    this.initialIndex = 0,
    this.autoPlayVideos = false,
  }) : super(key: key);
  
  @override
  State<StatusMediaViewer> createState() => _StatusMediaViewerState();
}

class _StatusMediaViewerState extends State<StatusMediaViewer> {
  late PageController _pageController;
  late int _currentIndex;
  final Map<String, VideoPlayerController> _videoControllers = {};
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    
    // Initialize first video if needed
    if (widget.mediaItems.isNotEmpty && _currentIndex < widget.mediaItems.length) {
      final media = widget.mediaItems[_currentIndex];
      if (media.isVideo) {
        _initializeVideoController(media);
      }
    }
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    // Dispose all video controllers
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    super.dispose();
  }
  
  Future<void> _initializeVideoController(StatusMedia media) async {
    if (!media.isVideo || _videoControllers.containsKey(media.id)) return;
    
    try {
      final controller = VideoPlayerController.network(media.url);
      _videoControllers[media.id] = controller;
      
      await controller.initialize();
      controller.setLooping(true);
      
      if (widget.autoPlayVideos) {
        controller.play();
      }
      
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }
  
  void _onPageChanged(int index) {
    // Pause current video
    if (_currentIndex < widget.mediaItems.length) {
      final currentMedia = widget.mediaItems[_currentIndex];
      if (currentMedia.isVideo) {
        final controller = _videoControllers[currentMedia.id];
        controller?.pause();
      }
    }
    
    setState(() {
      _currentIndex = index;
    });
    
    // Initialize and play next video if needed
    if (index < widget.mediaItems.length) {
      final nextMedia = widget.mediaItems[index];
      if (nextMedia.isVideo) {
        _initializeVideoController(nextMedia).then((_) {
          if (widget.autoPlayVideos && mounted) {
            _videoControllers[nextMedia.id]?.play();
            setState(() {});
          }
        });
      }
    }
  }
  
  void _togglePlayPause(StatusMedia media) {
    if (!media.isVideo) return;
    
    final controller = _videoControllers[media.id];
    if (controller == null) return;
    
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
    
    setState(() {});
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.mediaItems.isEmpty) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            'No media available',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1}/${widget.mediaItems.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (context, index) {
          final media = widget.mediaItems[index];
          
          if (media.isVideo) {
            return PhotoViewGalleryPageOptions.customChild(
              child: _buildVideoView(media),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              heroAttributes: PhotoViewHeroAttributes(tag: 'media-${media.id}'),
            );
          } else {
            return PhotoViewGalleryPageOptions(
              imageProvider: CachedNetworkImageProvider(media.url),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              heroAttributes: PhotoViewHeroAttributes(tag: 'media-${media.id}'),
            );
          }
        },
        itemCount: widget.mediaItems.length,
        loadingBuilder: (context, event) => Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              value: event == null
                  ? 0
                  : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
            ),
          ),
        ),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        pageController: _pageController,
        onPageChanged: _onPageChanged,
      ),
    );
  }
  
  Widget _buildVideoView(StatusMedia media) {
    final controller = _videoControllers[media.id];
    final isInitialized = controller?.value.isInitialized ?? false;
    final isPlaying = controller?.value.isPlaying ?? false;
    
    return GestureDetector(
      onTap: () => _togglePlayPause(media),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: controller!.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            )
          else
            Center(
              child: media.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: media.thumbnailUrl!,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => 
                          const CircularProgressIndicator(color: Colors.white),
                      errorWidget: (context, url, error) => 
                          const Icon(Icons.error, color: Colors.white),
                    )
                  : const CircularProgressIndicator(color: Colors.white),
            ),
          
          if (isInitialized && !isPlaying)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 50,
              ),
            ),
          
          if (isInitialized)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                controller!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.white,
                  bufferedColor: Colors.white70,
                  backgroundColor: Colors.white24,
                ),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              ),
            ),
        ],
      ),
    );
  }
}