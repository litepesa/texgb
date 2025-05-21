// lib/features/channels/widgets/channel_video_item.dart
// Updated with preloaded controller support and removed profile button

import 'package:flutter/material.dart';
import 'package:textgb/features/channels/models/channel_video_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/channels/providers/channel_videos_provider.dart';
import 'package:textgb/constants.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ChannelVideoItem extends ConsumerStatefulWidget {
  final ChannelVideoModel video;
  final bool isActive;
  final Function(VideoPlayerController)? onVideoControllerReady;
  // Add support for preloaded controller
  final VideoPlayerController? preloadedController;
  
  const ChannelVideoItem({
    Key? key,
    required this.video,
    required this.isActive,
    this.onVideoControllerReady,
    this.preloadedController,
  }) : super(key: key);

  @override
  ConsumerState<ChannelVideoItem> createState() => _ChannelVideoItemState();
}

class _ChannelVideoItemState extends ConsumerState<ChannelVideoItem> {
  VideoPlayerController? _videoPlayerController;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _hasError = false;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeMedia();
  }

  @override
  void didUpdateWidget(ChannelVideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle active state changes
    if (widget.isActive != oldWidget.isActive) {
      if (widget.video.isMultipleImages) {
        // No video to play/pause for image carousel
        return;
      }
      
      if (widget.isActive && _isInitialized && !_isPlaying) {
        _videoPlayerController?.play();
        setState(() {
          _isPlaying = true;
        });
        
        // Notify parent that controller is ready if it wasn't already
        if (widget.onVideoControllerReady != null && _videoPlayerController != null) {
          widget.onVideoControllerReady!(_videoPlayerController!);
        }
      } else if (!widget.isActive && _isInitialized && _isPlaying) {
        _videoPlayerController?.pause();
        setState(() {
          _isPlaying = false;
        });
      }
    }
    
    // Handle video URL changes
    if (widget.video.videoUrl != oldWidget.video.videoUrl ||
        widget.video.isMultipleImages != oldWidget.video.isMultipleImages ||
        widget.preloadedController != oldWidget.preloadedController) {
      // Dispose old controller if we created it (not if it was preloaded)
      if (_isInitialized && _videoPlayerController != null && oldWidget.preloadedController == null) {
        _videoPlayerController!.dispose();
        _videoPlayerController = null;
        _isInitialized = false;
      }
      
      // Initialize with new media
      _initializeMedia();
    }
  }

  // Update the _initializeMedia method to use preloaded controller if available
  void _initializeMedia() async {
    if (widget.video.isMultipleImages) {
      // For carousel posts, no video initialization needed
      setState(() {
        _isInitialized = true;
        _hasError = false;
      });
      return;
    }
    
    // For video posts
    debugPrint('Initializing video: ${widget.video.id} (${widget.video.videoUrl})');
    
    try {
      // Use preloaded controller if available
      if (widget.preloadedController != null) {
        debugPrint('Using preloaded controller for ${widget.video.id}');
        _videoPlayerController = widget.preloadedController;
        
        if (_videoPlayerController!.value.isInitialized) {
          // Controller is already initialized
          if (mounted) {
            setState(() {
              _isInitialized = true;
              _hasError = false;
            });
            
            // Auto-play if this item is active
            if (widget.isActive) {
              _videoPlayerController!.play();
              setState(() {
                _isPlaying = true;
              });
              
              // Notify parent about ready controller
              if (widget.onVideoControllerReady != null) {
                widget.onVideoControllerReady!(_videoPlayerController!);
              }
            }
          }
        } else {
          // Wait for initialization to complete
          await _videoPlayerController!.initialize();
          _videoPlayerController!.setLooping(true);
          
          if (mounted) {
            setState(() {
              _isInitialized = true;
              _hasError = false;
            });
            
            // Auto-play if this item is active
            if (widget.isActive) {
              _videoPlayerController!.play();
              setState(() {
                _isPlaying = true;
              });
              
              // Notify parent about ready controller
              if (widget.onVideoControllerReady != null) {
                widget.onVideoControllerReady!(_videoPlayerController!);
              }
            }
          }
        }
      } else {
        // Create a new controller
        _videoPlayerController = VideoPlayerController.network(widget.video.videoUrl);
        await _videoPlayerController!.initialize();
        _videoPlayerController!.setLooping(true);
        
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _hasError = false;
          });
          
          // Auto-play if this item is active
          if (widget.isActive) {
            _videoPlayerController!.play();
            setState(() {
              _isPlaying = true;
            });
            
            // Notify parent about ready controller
            if (widget.onVideoControllerReady != null) {
              widget.onVideoControllerReady!(_videoPlayerController!);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    // Only dispose the controller if we created it (not if it was preloaded)
    if (_isInitialized && _videoPlayerController != null && widget.preloadedController == null) {
      _videoPlayerController!.dispose();
    }
    _videoPlayerController = null;
    super.dispose();
  }

  void _togglePlayPause() {
    if (widget.video.isMultipleImages) {
      // No video to toggle for image carousel
      return;
    }
    
    if (!_isInitialized || _videoPlayerController == null) return;
    
    setState(() {
      if (_isPlaying) {
        _videoPlayerController!.pause();
      } else {
        _videoPlayerController!.play();
      }
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Media content (video or image carousel)
        _buildMediaContent(modernTheme),
            
        // Gradient overlay at the bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        
        // Channel information overlay
        Positioned(
          bottom: 20,
          left: 16,
          right: 70,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Channel name
              GestureDetector(
                onTap: () => _navigateToChannelProfile(),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: modernTheme.primaryColor!.withOpacity(0.2),
                      backgroundImage: widget.video.channelImage.isNotEmpty
                          ? NetworkImage(widget.video.channelImage)
                          : null,
                      child: widget.video.channelImage.isEmpty
                          ? Text(
                              widget.video.channelName.isNotEmpty
                                  ? widget.video.channelName[0]
                                  : "C",
                              style: TextStyle(
                                color: modernTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Row(
                      children: [
                        Text(
                          widget.video.channelName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Caption
              Text(
                widget.video.caption,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // Tags
              if (widget.video.tags.isNotEmpty)
                SizedBox(
                  height: 24,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.video.tags.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '#${widget.video.tags[index]}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        
        // Right side action buttons - REMOVED PROFILE BUTTON
        Positioned(
          bottom: 20,
          right: 16,
          child: Column(
            children: [
              // Like button
              _buildActionButton(
                Icons.favorite,
                widget.video.likes.toString(),
                modernTheme.primaryColor!,
                () {
                  ref.read(channelVideosProvider.notifier).likeVideo(widget.video.id);
                },
                isActive: widget.video.isLiked,
              ),
              
              const SizedBox(height: 20),
              
              // Comment button
              _buildActionButton(
                Icons.comment,
                widget.video.comments.toString(),
                Colors.white,
                () {
                  // Navigate to comments
                  Navigator.of(context).pushNamed(
                    Constants.channelCommentsScreen,
                    arguments: widget.video.id,
                  );
                },
              ),
              
              const SizedBox(height: 20),
              
              // Share button
              _buildActionButton(
                Icons.share,
                "Share",
                Colors.white,
                () {
                  // Show share options
                },
              ),
                
              if (!widget.video.isMultipleImages && !_isInitialized)
                const SizedBox(height: 20),
                
              // Play/pause indicator (only appears when video is loading)
              if (!widget.video.isMultipleImages && !_isInitialized)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
            ],
          ),
        ),
        
        // Play/pause indicator in the center (only appears while playing videos)
        if (!widget.video.isMultipleImages && _isInitialized && !_isPlaying)
          Center(
            child: Container(
              width: 70,
              height: 70,
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
          ),
          
        // Image carousel indicator
        if (widget.video.isMultipleImages && widget.video.imageUrls.length > 1)
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.video.imageUrls.length, (index) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
  
  Widget _buildMediaContent(ModernThemeExtension modernTheme) {
    // Handle image carousel
    if (widget.video.isMultipleImages) {
      if (widget.video.imageUrls.isEmpty) {
        return Center(
          child: Icon(
            Icons.image_not_supported,
            color: Colors.white.withOpacity(0.7),
            size: 64,
          ),
        );
      }
      
      return CarouselSlider(
        options: CarouselOptions(
          height: double.infinity,
          viewportFraction: 1.0,
          enableInfiniteScroll: widget.video.imageUrls.length > 1,
          autoPlay: widget.isActive && widget.video.imageUrls.length > 1,
          autoPlayInterval: const Duration(seconds: 3),
          onPageChanged: (index, reason) {
            setState(() {
              _currentImageIndex = index;
            });
          },
        ),
        items: widget.video.imageUrls.map((imageUrl) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
            ),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    color: modernTheme.primaryColor,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / 
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white.withOpacity(0.7),
                    size: 64,
                  ),
                );
              },
            ),
          );
        }).toList(),
      );
    }
    
    // Handle video content
    return _hasError
      ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Could not load video',
                style: TextStyle(color: Colors.white),
              ),
              TextButton(
                onPressed: _initializeMedia,
                child: Text('Retry'),
              ),
            ],
          ),
        )
      : _isInitialized && _videoPlayerController != null
          ? GestureDetector(
              onTap: _togglePlayPause,
              child: VideoPlayer(_videoPlayerController!),
            )
          : Center(
              child: CircularProgressIndicator(
                color: modernTheme.primaryColor,
              ),
            );
  }
  
  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    Function() onTap, {
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive ? color : Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : color,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  void _navigateToChannelProfile() {
    Navigator.of(context).pushNamed(
      Constants.channelProfileScreen,
      arguments: widget.video.channelId,
    );
  }
}