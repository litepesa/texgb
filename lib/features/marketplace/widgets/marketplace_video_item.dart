// lib/features/marketplace/widgets/marketplace_video_item.dart
import 'package:flutter/material.dart';
import 'package:textgb/features/marketplace/models/marketplace_video_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/marketplace/providers/marketplace_provider.dart';

class MarketplaceVideoItem extends ConsumerStatefulWidget {
  final MarketplaceVideoModel video;
  final bool isActive;
  
  const MarketplaceVideoItem({
    Key? key,
    required this.video,
    required this.isActive,
  }) : super(key: key);

  @override
  ConsumerState<MarketplaceVideoItem> createState() => _MarketplaceVideoItemState();
}

class _MarketplaceVideoItemState extends ConsumerState<MarketplaceVideoItem> {
  late VideoPlayerController _videoPlayerController;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(MarketplaceVideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle active state changes
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive && _isInitialized && !_isPlaying) {
        _videoPlayerController.play();
        setState(() {
          _isPlaying = true;
        });
      } else if (!widget.isActive && _isInitialized && _isPlaying) {
        _videoPlayerController.pause();
        setState(() {
          _isPlaying = false;
        });
      }
    }
    
    // Handle video URL changes
    if (widget.video.videoUrl != oldWidget.video.videoUrl) {
      // Dispose old controller
      if (_isInitialized) {
        _videoPlayerController.dispose();
      }
      
      // Initialize with new URL
      _initializeVideo();
    }
  }

  void _initializeVideo() async {
    debugPrint('Initializing video: ${widget.video.id} (${widget.video.videoUrl})');
    
    try {
      _videoPlayerController = VideoPlayerController.network(widget.video.videoUrl);
      await _videoPlayerController.initialize();
      _videoPlayerController.setLooping(true);
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
        
        // Auto-play if this item is active
        if (widget.isActive) {
          _videoPlayerController.play();
          setState(() {
            _isPlaying = true;
          });
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
    if (_isInitialized) {
      _videoPlayerController.dispose();
    }
    super.dispose();
  }

  void _togglePlayPause() {
    if (!_isInitialized) return;
    
    setState(() {
      if (_isPlaying) {
        _videoPlayerController.pause();
      } else {
        _videoPlayerController.play();
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
        // Video player
        _hasError
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
                    onPressed: _initializeVideo,
                    child: Text('Retry'),
                  ),
                ],
              ),
            )
          : _isInitialized 
              ? GestureDetector(
                  onTap: _togglePlayPause,
                  child: VideoPlayer(_videoPlayerController),
                )
              : Center(
                  child: CircularProgressIndicator(
                    color: modernTheme.primaryColor,
                  ),
                ),
            
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
        
        // Video information overlay
        Positioned(
          bottom: 20,
          left: 16,
          right: 70,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Username and business name
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: modernTheme.primaryColor!.withOpacity(0.2),
                    backgroundImage: widget.video.userImage.isNotEmpty
                        ? NetworkImage(widget.video.userImage)
                        : null,
                    child: widget.video.userImage.isEmpty
                        ? Text(
                            widget.video.userName.isNotEmpty
                                ? widget.video.userName[0]
                                : "U",
                            style: TextStyle(
                              color: modernTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.video.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (widget.video.businessName.isNotEmpty)
                        Text(
                          widget.video.businessName,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Product name and price
              Text(
                widget.video.productName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              
              const SizedBox(height: 6),
              
              // Price
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: modernTheme.primaryColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      widget.video.price,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 10),
                  
                  // Category tag
                  if (widget.video.category.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        widget.video.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Description
              Text(
                widget.video.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        
        // Right side action buttons
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
                  ref.read(marketplaceProvider.notifier).likeVideo(widget.video.id);
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
                    '/marketplaceCommentsScreen',
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
              
              const SizedBox(height: 20),
              
              // Contact button
              _buildActionButton(
                Icons.message,
                "Contact",
                Colors.white,
                () {
                  // Contact seller
                },
              ),
              
              if (!_isInitialized)
                const SizedBox(height: 20),
                
              // Play/pause indicator (only appears when video is loading)
              if (!_isInitialized)
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
        
        // Play/pause indicator in the center (only appears while playing)
        if (_isInitialized && !_isPlaying)
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
      ],
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
}